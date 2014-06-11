#!/usr/bin/python
# -*- coding: utf-8 -*-

# Written by Zachary Murray (dremelofdeath) on 11/04/2013.
# Your right to steal this is reserved. <3

import argparse
import base64
import errno
import json
import os
import subprocess
import sys

from collections import namedtuple


parser = argparse.ArgumentParser(
    description = 'Intelligently links your dotfiles to your home directory.',
    epilog = 'Written by Zachary Murray (dremelofdeath). Yours to steal and love.',
)

parser.add_argument('-v', '--verbose',
    dest = 'verbose',
    action = 'store_true',
    help = 'turn on verbose logging',
)
parser.set_defaults(feature=False)

parser.add_argument('--clean',
    dest = 'clean',
    action = 'store_true',
    help = 'erase a current situate deployment and start over',
)
parser.set_defaults(clean=False)

parser.add_argument('-n', '--dry_run',
    dest = 'dry_run',
    action = 'store_true',
    help = 'do not perform real filesystem operations (for testing)',
)
parser.set_defaults(dry_run=False)

parser.add_argument('-q', '--quiet',
    dest = 'quiet',
    action = 'store_true',
    help = "be quiet; don't display info messages",
)
parser.set_defaults(quiet=False)

parser.add_argument('--silent',
    action = 'store_true',
    help = 'be completely silent: print absolutely nothing',
)
parser.set_defaults(silent=False)

parser.add_argument('--backtrace',
    action = 'store_true',
    help = 'play rough and raise all exceptions (for testing)',
)
parser.set_defaults(backtrace=False)

parser.add_argument('--script_path',
    type = str,
    help = 'internal: base path for the dotfiles deployment',
    default = os.path.dirname(os.path.realpath(__file__)),
)

parser.add_argument('--symmap',
    type = str,
    help = 'internal: filename of the JSON symbol map',
    default = "symmap.json",
)

parser.add_argument('--target_path',
    type = str,
    help = 'internal: base path for situation target',
    default = os.getcwd(),
)

parser.add_argument('--situation_file',
    type = str,
    help = 'internal: filename of the situation file',
    default = '.situation',
)

args = parser.parse_args()


class bcolors:
  HEADER = '\033[95m'
  OKBLUE = '\033[94m'
  OKGREEN = '\033[92m'
  WARNING = '\033[93m'
  FAIL = '\033[91m'
  VERBOSE = '\033[90m'
  ENDC = '\033[0m'

  @classmethod
  def disable(cls):
    cls.HEADER = ''
    cls.OKBLUE = ''
    cls.OKGREEN = ''
    cls.WARNING = ''
    cls.FAIL = ''
    cls.ENDC = ''


class PlatformComputer:
  @staticmethod
  def is_compatible_platform(platform_to_check):
    if platform_to_check == 'win32' or platform_to_check == 'win64':
      if platform_to_check == 'win64':
        Log.warning('using unsupported platform keyword win64')
      return platform_to_check == sys.platform
    elif platform_to_check == 'windows' or platform_to_check == 'win':
      return sys.platform.startswith('win')
    elif platform_to_check == 'unix':
      # ...good enough?
      invalid_prefixes = ['os2', 'win', 'risc', 'generic', 'unknown']
      for prefix in invalid_prefixes:
        if sys.platform.startswith(prefix):
          return False
      return True
    elif platform_to_check == 'linux':
      return sys.platform.startswith('linux')
    else:
      return platform_to_check == sys.platform

  @staticmethod
  def should_disable_color():
    if sys.platform.startswith('win') and sys.version_info[0] >= 3:
      return True
    return False


class Operation:
  def process(self, *unused_args, **unused_kwargs):
    raise NotImplementedError("process() must be overridden")


class OperationSets:
  Unix = {
      'symlink': lambda x, y: os.symlink(x, y),
      'copy': 'cp "%s" "%s"',
      'delete': lambda x, y: OperationSets.shared_delete(y),
  }
  Windows = {
      'symlink': lambda x, y: OperationSets.windows_symlink(x, y),
      'copy': 'copy "%s" "%s"',
      'delete': lambda unused_x, y: OperationSets.shared_delete(y),
  }

  @staticmethod
  def get_op_set():
    if sys.platform.startswith('win'):
      return OperationSets.Windows
    # This is probably okay as a default... right? Right?
    return OperationSets.Unix

  @staticmethod
  def windows_symlink(x, y):
    if os.path.exists(y):
      # Just raise the error here to mimic the os.symlink() implementation
      raise OSError(errno.EEXIST, "Symlink already exists")
    flags = []
    if os.path.isdir(x):
      flags.append("/D")
    # Note here that on Windows the x and y are backwards.
    actual_command = 'mklink %s "%s" "%s"' % (' '.join(flags), y, x)
    Log.verbose('Creating a Windows symlink via: %s' % actual_command)
    Log.verbose(subprocess.check_output(actual_command, shell=True))

  @staticmethod
  def is_windows_symlink(target):
    if sys.platform.startswith('win'):
      command = 'fsutil reparsepoint query "%s"'
      try:
        output = subprocess.check_output(command % target)
        return output.find('Symbolic Link') != -1
      except subprocess.CalledProcessError:
        return False
    return False

  @staticmethod
  def shared_delete(x):
    if os.path.isdir(x) and OperationSets.is_windows_symlink(x):
      try:
        actual_command = 'rmdir "%s"' % x
        Log.verbose('Deleting a Windows symlink via: %s' % actual_command)
        subprocess.check_call(actual_command, shell=True)
      except WindowsError as e:
        # This is particularly weird... didn't we just check the file was a
        # directory? That should return false if there's nothing there...
        if e.errno == errno.ENOENT:
          # Intercept the exception and throw one we understand for deletes
          raise FileVanishedError('File %s was here, but not anymore...' % x)
        raise e
    elif os.path.isdir(x) and not os.path.islink(x):
      Log.verbose("deleting a copied directory: %s" % x)
      # This should happen only for copies.
      os.rmdir(x)
    else:
      try:
        os.unlink(x)  # This will also delete copied files.
      except OSError as e:
        if e.errno == errno.ENOENT:
          raise AlreadyDeletedError('File %s has already been deleted' % x)
        raise e


class FileOperation(Operation):
  Types = OperationSets.get_op_set()

  def __init__(self, package, type, operand1='', operand2=''):
    self.package = package
    self.command = FileOperation.Types[type]
    self.type = type
    self.operand1 = operand1
    self.operand2 = operand2

  def run_command(self, from_target, to_target):
    try:
      self.command(from_target, to_target)
    except TypeError:
      # Not a function, it's a shell command.
      actual_command = self.command % (from_target, to_target)
      Log.verbose("running shell command: %s" % actual_command)
      subprocess.check_call(actual_command)

  def process(self, from_path, to_path):
    from_target = os.path.join(from_path, self.package, self.operand1)
    to_target = os.path.join(to_path, self.operand2)
    Log.verbose(
        "perform: %s (%s, %s)" % (self.type, from_target, to_target))
    # TODO(dremelofdeath): Need to actually use dry_run, also do the op
    if not args.dry_run:
      try:
        if os.path.isdir(from_target):
          self.run_command(from_target, to_target)
        else:
          with open(from_target):
            self.run_command(from_target, to_target)
      except AlreadyDeletedError:
        Log.warn('file already deleted: %s' % (to_target))
      except OSError as e:
        if e.errno == errno.EEXIST:
          Log.warn('file already exists: %s' % (to_target))
        elif e.errno == errno.ENOENT:
          Log.fail('target hit an OSError! this is probably a bug!')
          raise
        else:
          raise
      except IOError as e:
        if e.errno == errno.ENOENT:
          message = "in package %s: file doesn't exist: %s" % (
              self.package, from_target)
          raise SourceFileMissingError(message)
        else:
          raise


class MultiFileOperation(Operation):
  def __init__(self, *operations):
    self.operations = operations

  def process(self, from_path, to_path):
    for each in self.operations:
      each.process(from_path, to_path)


class AnalysisError(Exception):
  pass


class CircularDependencyError(AnalysisError):
  pass


class NonexistentDependencyError(AnalysisError):
  pass


class OperationError(Exception):
  pass


class SourceFileMissingError(OperationError):
  pass


class AlreadyFailedError(OperationError):
  pass


class AlreadyDeletedError(OperationError):
  pass


class FileVanishedError(AlreadyDeletedError):
  pass


class ErrorAmalgam(Exception):
  def __init__(self, message, first_error):
    Exception.__init__(self, message)
    self.error_list = [ first_error ]
    self.failed = None  # Use this to track which packages failed

  def __len__(self):
    return len(self.error_list)


class Log:
  @staticmethod
  def message(type, colorlevel, text):
    if not args.silent:
      print('[ %s%s%s ]: %s' % (
          colorlevel,
          type,
          bcolors.ENDC,
          text
      ))

  @staticmethod
  def verbose(text):
    if args.verbose and not args.quiet:
      Log.message("INFO", bcolors.VERBOSE, text)

  @staticmethod
  def info(text):
    if not args.quiet:
      Log.message("INFO", bcolors.OKBLUE, text)

  @staticmethod
  def warn(text):
    Log.message("WARN", bcolors.WARNING, text)

  @staticmethod
  def fail(text):
    Log.message("FAIL", bcolors.FAIL, text)

  @staticmethod
  def success(text):
    Log.message(" OK ", bcolors.OKGREEN, text)


class SituationFile:
  def __init__(self, symmap={}, complete={}, skipped={}, failed={},
               filename=None):
    self.last_symmap = symmap
    self.complete = complete
    self.skipped = skipped
    self.failed = failed
    if filename is not None:
      self.read(filename)

  def read(self, filename):
    with open(os.path.join(args.target_path, args.situation_file), 'r') as f:
      situation_json = json.load(f)
      self.last_symmap = json.loads(
          base64.b64decode(situation_json['last_symmap']))
      self.complete = situation_json['complete']
      self.skipped = situation_json['skipped']
      self.failed = situation_json['failed']

  def write(self, filename=None):
    if not filename:
      filename = os.path.join(args.target_path, args.situation_file)
    with open(filename, 'w') as f:
      situation_json = {
          'last_symmap':
              base64.b64encode(json.dumps(self.last_symmap).encode('ascii')),
          'complete': self.complete,
          'skipped': self.skipped,
          'failed': self.failed,
      }
      json.dump(situation_json, f)

  def get_retryable_packages(self):
    return self.failed

  def get_new_differences(self, new_symmap):
    new_key_set = set(new_symmap.keys())
    last_key_set = set(self.last_symmap.keys())
    intersection = new_key_set.intersection(last_key_set)
    new_packages = new_key_set - intersection
    removed_packages = last_key_set - intersection
    changed_packages = set(pkg for pkg in intersection
                           if new_symmap[pkg] != self.last_symmap[pkg])
    return (new_packages, removed_packages, changed_packages)


PackageInfo = namedtuple('PackageInfo', ['new', 'removed', 'changed'])


def process_package_file(package_name, package_file, package_info=None):
  from_attr = ''
  to_attr = ''
  platform_attr = []
  try:
    # It might be an object...
    try:
      from_attr = package_file['from']
      to_attr = package_file['to']
    except KeyError:
      # It might just have a name with other directives too
      from_attr = package_file['name']
      to_attr = package_file['name']
    # At this point, we know it's a string if we've thrown the TypeError again.
    try:
      platform_attr = [package_file['platform']]
    except KeyError:
      try:
        # It could also be a list; make it a set if so.
        platform_attr = frozenset(package_file['platforms'])
      except KeyError:
        # We don't care.
        pass
  except TypeError:
    # Nah, just a string I guess
    from_attr = package_file
    to_attr = package_file

  # Now, do all the processing magic.
  compatible_platform = True
  if platform_attr:
    # Check if any platform is compatible with the desired one(s).
    compatible_platform = reduce(
        lambda x, y: x or y,
        map(PlatformComputer.is_compatible_platform, platform_attr))

  if compatible_platform:
    operation = 'symlink'
    if args.clean:
      operation = 'delete'
    elif package_info:
      if package_name in package_info.removed:
        operation = 'delete'
      elif package_name in package_info.changed:
        Log.verbose('operation: %s [%s -> %s]' % (
          'delete, symlink', from_attr, to_attr))
        # TODO(dremelofdeath): Think about per-file changes only?
        # Just clear out the package and relink it.
        return MultiFileOperation(
            FileOperation(package_name, 'delete', from_attr, to_attr),
            FileOperation(package_name, 'symlink', from_attr, to_attr))
    Log.verbose('operation: %s [%s -> %s]' % (operation, from_attr, to_attr))
    return FileOperation(package_name, operation, from_attr, to_attr)
  
  Log.verbose('skipping file %s' % from_attr)
  return None


def process_package_files(package_name, package_files, package_info=None):
  return [process_package_file(package_name, each, package_info)
          for each in package_files if each is not None]


def process_package(package_name, symmap, package_info=None):
  # Check first to see if we have to touch this package at all.
  if package_info:
    if package_name not in reduce(lambda x, y: x.union(y), package_info):
      # This package is unchanged.
      # TODO(dremelofdeath): Make these Nones reason codes.
      return None

  package_obj = symmap[package_name]

  package_ops = {}

  for each in package_obj:
    # Try to figure out what kind of statement we have.
    if each == 'file':
      if 'ops' not in package_ops:
        package_ops['ops'] = []
      file = process_package_file(package_name, package_obj[each], package_info)
      if file:
        package_ops['ops'].append(file)
    elif each == 'files':
      if 'ops' not in package_ops:
        package_ops['ops'] = []
      files = process_package_files(
          package_name, package_obj[each], package_info)
      package_ops['ops'] += files
    elif each == 'depends':
      if package_obj[each]:
        if 'depends' not in package_ops:
          package_ops['depends'] = []
        if isinstance(package_obj[each], basestring):
          package_ops['depends'].append(package_obj[each])
        else:
          package_ops['depends'] += package_obj[each]
    elif each == 'platform':
      # Check the platform and abort if it's not compatible.
      if not PlatformComputer.is_compatible_platform(package_obj[each]):
        Log.verbose('skipping incompatible package "%s"' % package_name)
        return None
    else:
      # Probably should warn that this is not valid, whatever it is.
      Log.warn('unknown directive %s specified in package %s' % (
        each,
        package_name))

  return package_ops


def chain_from_stack(stack):
  chain = stack[:]
  chain.reverse()
  return chain


def check_single_dependency(package_name, operations, dep_stack=[]):
  for each in dep_stack:
    if each == package_name:
      message = "package %s contains a circular dependency (chain: %s)" % (
          package_name,
          "->".join(chain_from_stack(dep_stack)),
      )
      raise CircularDependencyError(message)
  try:
    if 'depends' in operations[package_name]:
      next_stack = dep_stack[:]
      next_stack.insert(0, package_name)
      depends = operations[package_name]['depends']
      if isinstance(depends, basestring):
        check_single_dependency(depends, operations, next_stack)
      else:
        for each in depends:
          check_single_dependency(each, operations, next_stack)
  except KeyError:
    message = "package %s depends on nonexistent package %s (chain: %s)" % (
        dep_stack[0],
        package_name,
        "->".join(chain_from_stack(dep_stack)),
    )
    if sys.version_info[0] >= 3:
      eval('raise NonexistentDependencyError(message) from sys.exc_info()[1]')
    else:
      eval('raise NonexistentDependencyError(message), None, sys.exc_info()[2]')


def check_dependencies(operations):
  errors = None
  for each in operations:
    try:
      if operations[each]:
        check_single_dependency(each, operations)
      else:
        Log.verbose('dependencies irrelevant for skipped package %s' % each)
    except Exception as e:
      if args.backtrace:
        raise
      if not errors:
        errors = ErrorAmalgam('errors while checking dependencies', e)
      else:
        errors.error_list.append(e)
      Log.fail(e.message)
  if errors:
    raise errors


def perform_single_operation(package_name, operations, complete, failed={}):
  # First, check to see if this package is already complete
  if package_name in complete:
    return (complete, failed)

  # If it previously failed, don't retry it.
  if package_name in failed:
    raise AlreadyFailedError(
        'package %s already failed, not retrying' % (package_name))

  # If not, check its dependencies and perform them if necessary
  if 'depends' in operations[package_name]:
    try:
      depends = operations[package_name]['depends']
      if isinstance(depends, basestring):
        complete, failed = perform_single_operation(
            depends, operations, complete, failed)
      else:
        for each in depends:
          complete, failed = perform_single_operation(
              each, operations, complete, failed)
    except Exception:  # TODO(dremelofdeath): Maybe not catch everything here?
      msg = 'not %s package %s because a dependent package failed' % (
          get_verb('progressive'), package_name)
      Log.fail(msg)
      failed[package_name] = True
      raise

  # Then finally come back and perform this package's operations
  errors = None
  try:
    operations[package_name]['ops'].process(args.script_path, args.target_path)
  except AttributeError:
    # It could also be a list of operations.
    for each_operation in operations[package_name]['ops']:
      try:
        each_operation.process(args.script_path, args.target_path)
      except OperationError as e:
        if args.backtrace:
          raise
        if not errors:
          message = 'errors while %s package %s' % (
              get_verb('progressive'), package_name)
          errors = ErrorAmalgam(message, e)
        else:
          errors.error_list.append(e)
        Log.fail(e.message)
  except KeyError:
    # This is almost certainly because 'ops' isn't in the object.
    # We should probably warn about this.
    Log.warn('no operations defined for package %s' % (package_name))
  except OperationError as e:
    # TODO(dremelofdeath): I'm not actually sure this codepath is ever hit.
    if args.backtrace:
      raise
    message = 'errors while %s package %s' % (
        get_verb('progressive'), package_name)
    errors = ErrorAmalgam(message, e)

  if errors:
    num_err = len(errors.error_list)
    Log.fail('%s package %s failed with %d error%s' %
        (get_verb('progressive'), package_name, num_err,
         's' if num_err != 1 else ''))
    failed[package_name] = True
    errors.failed = failed
    raise errors

  # And now mark this operation complete
  complete[package_name] = True
  
  Log.success('package %s successfully %s!' % (package_name, get_verb()))
  return (complete, failed)


def perform_operations(operations):
  complete = {}
  skipped = {}
  failed = {}

  errors = None

  for package_name in operations:
    try:
      if operations[package_name]:
        complete, failed = perform_single_operation(
            package_name, operations, complete, failed)
      else:
        Log.verbose('not processing package marked skipped: %s' % package_name)
        skipped[package_name] = True
    except AlreadyFailedError as e:
      if not errors:
        errors = ErrorAmalgam('some packages failed in processing', e)
      else:
        errors.error_list.append(e)
      Log.fail(e.message)
    except OperationError as e:
      if args.backtrace:
        raise
      if not errors:
        errors = ErrorAmalgam('some packages failed in processing', e)
      else:
        errors.error_list.append(e)
      Log.fail(e.message)
      Log.info('a package failed, attempting to continue...')
    except ErrorAmalgam as e:
      if args.backtrace:
        raise
      if not errors:
        # amalgamception
        errors = ErrorAmalgam('some packages failed in processing', e)
        errors.failed = e.failed
      else:
        errors.error_list.append(e)
        errors.failed.update(e.failed)

  return (complete, skipped, failed, errors)


def get_verb(tense='perfect'):
  if tense == 'perfect':
    if args.clean:
      return 'cleaned'
    return 'situated'
  elif tense == 'progressive':
    if args.clean:
      return 'cleaning'
    return 'situating'


def check_windows_elevation():
  if sys.platform.startswith('win'):
    try:
      subprocess.check_call('cmd /q /c at > NUL')
    except subprocess.CalledProcessError:
      Log.fail('You must run this script from an elevated command prompt.')
      Log.fail('Right-click cmd.exe and choose "Run as administrator".')
      sys.exit(1)


def print_completion_message(complete, skipped, failed, errors):
  if failed:
    if errors:
      if (len(failed) != len(errors)):
        Log.warn("Failed/error mismatch. This is a bug, please report it.")
        if args.backtrace:
          raise errors
      numpkgs = len(errors)
      Log.fail(
          '%d package%s had errors' % (numpkgs, 's' if numpkgs != 1 else ''))
    else:
      Log.warn(
          "Errors object was missing in the failed completion handler."
          " This is a bug. Please report it.")
      # Try our best anyway to explain WTF just happened.
      numpkgs = len(failed)
      Log.fail(
          '%d package%s had errors' % (numpkgs, 's' if numpkgs != 1 else ''))
    return None
  elif errors:
    Log.warn(
      "There were %d errors, but no packages failed."
      " This is probably a bug." % len(errors))
  else:
    pkgs = len(complete)
    if pkgs:
      Log.success(
          '%d package%s successfully %s%s' % (
              pkgs,
              's' if pkgs != 1 else '',
              get_verb(),
              ' (%s skipped)' % len(skipped) if skipped else ''))
    else:
      Log.success('nothing to do!')

  Log.success('everything is OK!')


def main():
  # Before doing anything else, check if we need to disable color printouts.
  colors_disabled = PlatformComputer.should_disable_color()

  if colors_disabled:
    bcolors.disable()

  Log.info('situate.py -- written by Zachary Murray (dremelofdeath)')
  Log.info('great artists steal: the stealable way to rock your dotfiles(tm)')
  Log.info('')

  # On Windows, we need to verify first that we are elevated because symlinks
  # can't be created without administrator privileges.
  check_windows_elevation()

  Log.info('finding the symbol map')
  symmap = None
  symmap_path = os.path.join(args.script_path, args.symmap)
  try:
    symmap = json.load(open(symmap_path))
  except ValueError as e:
    Log.fail("couldn't parse symbol map: " + e.message)
    if args.backtrace:
      raise
    return None
  except IOError as e:
    Log.fail("couldn't open symbol map: " + e.message)
    if args.backtrace:
      raise
    return None
  except Exception as e:
    Log.fail('whatever is about to happen is a bug. report it!')
    Log.fail(e.message)
    raise

  if not symmap:
    Log.fail('symmap was never assigned! this is a bug, report this!')
    sys.exit(1)

  Log.success('completed reading the symbol map')

  situation_file = None
  try:
    situation_file = SituationFile(filename=args.situation_file)
  except IOError as e:
    if e.errno == errno.ENOENT:
      Log.verbose('no situation file found. first run scenario?')
    else:
      Log.fail('unexpected I/O error -- possibly a bug. details:')
      raise
  except Exception:
    Log.fail(
      'unexpected error while reading the situation file. please report this!')
    raise

  package_info = None
  if situation_file and not args.clean:
    package_info = PackageInfo._make(
      situation_file.get_new_differences(symmap))
    Log.verbose(
        'read this package_info from the %s file:' % args.situation_file)
    Log.verbose(str(package_info))

  operations = dict((pkg, process_package(pkg, symmap, package_info))
                    for pkg in symmap)

  Log.info('analyzing...')
  try:
    check_dependencies(operations)
    numpkgs = len(operations)
    Log.success('finished analyzing %d total package%s' %
        (numpkgs, 's' if numpkgs != 1 else ''))
  except ErrorAmalgam as e:
    Log.fail('giving up; %d errors encountered during analysis' % (
      len(e.error_list)))
    return None
  except Exception as e:
    Log.fail('an unexpected error occurred (this might be a bug)')
    Log.fail('please report this error message:')
    raise

  Log.info('%s dotfiles...' % get_verb('progressive'))
  try:
    complete, skipped, failed, errors = perform_operations(operations)

    if not args.clean:
      if len(complete) or len(failed) or not situation_file:
        Log.info('writing your %s file' % args.situation_file)
        SituationFile(symmap, complete, skipped, failed).write()
    elif situation_file:
      Log.info('cleaning up your %s file' % args.situation_file)
      try:
        os.unlink(os.path.join(args.target_path, args.situation_file))
      except OSError as e:
        if e.errno == errno.ENOENT:
          Log.warn("strange... you had a %s file, but now it's gone" % (
              args.situation_file))
        else:
          raise

    print_completion_message(complete, skipped, failed, errors)
  except Exception as e:
    Log.fail('an unexpected error occurred (this might be a bug)')
    Log.fail('please report this error message:')
    raise

if __name__ == '__main__':
  main()

