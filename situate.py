#!/usr/bin/python
# -*- coding: utf-8 -*-

# Written by Zachary Murray (dremelofdeath) on 11/04/2013.
# Your right to steal this is reserved. <3

import argparse
import errno
import json
import os
import platform
import subprocess
import sys


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

args = parser.parse_args()


class bcolors:
  HEADER = '\033[95m'
  OKBLUE = '\033[94m'
  OKGREEN = '\033[92m'
  WARNING = '\033[93m'
  FAIL = '\033[91m'
  VERBOSE = '\033[90m'
  ENDC = '\033[0m'

  def disable(self):
    self.HEADER = ''
    self.OKBLUE = ''
    self.OKGREEN = ''
    self.WARNING = ''
    self.FAIL = ''
    self.ENDC = ''


class Operation:
  def process(self):
    raise NotImplementedError("process() must be overridden")


class OperationSets:
  Unix = {
      #'symlink': 'ln -s "%s" "%s"',
      #'symlink': lambda x, y: Log.info("x: %s, y: %s" % (str(x), str(y))),
      'symlink': lambda x, y: os.symlink(x, y),
      'copy': 'cp "%s" "%s"',
  }
  Windows = {
      'symlink': lambda x, y: OperationSets.windows_symlink(x, y),
      'copy': 'copy "%s" "%s"',
  }

  @staticmethod
  def get_op_set():
    if platform.system() == 'Windows':
      return OperationSets.Windows
    return OperationsSets.Unix

  @staticmethod
  def windows_symlink(x, y):
    flags = []
    if os.path.isdir(x):
      flags.append("/D")
    # Note here that on Windows the x and y are backwards.
    actual_command = 'cmd /c mklink %s "%s" "%s"' % (' '.join(flags), y, x)
    Log.verbose('Creating a Windows symlink via: %s' % actual_command)
    subprocess.check_call(actual_command)


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


class ErrorAmalgam(Exception):
  def __init__(self, message, first_error):
    Exception.__init__(self, message)
    self.error_list = [ first_error ]


class Log:
  @staticmethod
  def message(type, colorlevel, text):
    if not args.silent:
      print '[ %s%s%s ]: %s' % (
          colorlevel,
          type,
          bcolors.ENDC,
          text
      )

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

def process_package_file(package_name, package_file):
  from_attr = ''
  to_attr=''
  try:
    # It might be an object...
    from_attr = package_file["from"]
    to_attr = package_file["to"]
  except TypeError:
    # Nah, just a string I guess
    from_attr = package_file
    to_attr = package_file
  Log.verbose("operation: symlink [%s -> %s]" % (from_attr, to_attr))
  return FileOperation(package_name, 'symlink', from_attr, to_attr)

def process_package_files(package_name, package_files):
  return [process_package_file(package_name, each) for each in package_files]

def process_package(package_name, symmap):
  package_obj = symmap[package_name]

  package_ops = {}

  for each in package_obj:
    # Try to figure out what kind of statement we have
    if each == 'file':
      if 'ops' not in package_ops:
        package_ops['ops'] = []
      file = process_package_file(package_name, package_obj[each])
      package_ops['ops'].append(file)
    elif each == 'files':
      if 'ops' not in package_ops:
        package_ops['ops'] = []
      files = process_package_files(package_name, package_obj[each])
      package_ops['ops'] += files
    elif each == 'depends':
      if package_obj[each]:
        if 'depends' not in package_ops:
          package_ops['depends'] = []
        if isinstance(package_obj[each], basestring):
          package_ops['depends'].append(package_obj[each])
        else:
          package_ops['depends'] += package_obj[each]
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
    # TODO(dremelofdeath): Consider using raise...from in Python 3.x later.
    raise NonexistentDependencyError(message), None, sys.exc_info()[2]

def check_dependencies(operations):
  errors = None
  for each in operations:
    try:
      check_single_dependency(each, operations)
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
    return complete

  # If it previously failed, don't retry it.
  if package_name in failed:
    raise AlreadyFailedError(
        'package %s already failed, not retrying' % (package_name))

  # If not, check its dependencies and perform them if necessary
  if 'depends' in operations[package_name]:
    try:
      depends = operations[package_name]['depends']
      if isinstance(depends, basestring):
        complete = perform_single_operation(
            depends, operations, complete, failed)
      else:
        for each in depends:
          complete = perform_single_operation(
              each, operations, complete, failed)
    except Exception:
      msg = 'not situating package %s because a dependent package failed' % (
          package_name)
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
          message = 'errors while situating package %s' % (package_name)
          errors = ErrorAmalgam(message, e)
        else:
          errors.error_list.append(e)
        Log.fail(e.message)
  except KeyError:
    # This is almost certainly because 'ops' isn't in the object.
    # We should probably warn about this.
    Log.warn('no operations defined for package %s' % (package_name))
  except OperationError as e:
    if args.backtrace:
      raise
    errors = ErrorAmalgam('errors while checking dependencies', e)

  if errors:
    num_err = len(errors.error_list)
    Log.fail('situating package %s failed with %d error%s' %
        (package_name, num_err, 's' if num_err != 1 else ''))
    failed[package_name] = True
    raise errors

  # And now mark this operation complete
  complete[package_name] = True
  
  Log.success('package %s successfully situated!' % (package_name))
  return complete

def perform_operations(operations):
  complete = {}

  errors = None

  for each in operations:
    try:
      complete = perform_single_operation(each, operations, complete)
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

  if errors:
    raise errors

  pkgs = len(complete)
  Log.success(
      '%d package%s successfully situated' % (pkgs, 's' if pkgs != 1 else ''))
  return complete

def main():
  Log.info('situate.py -- written by Zachary Murray (dremelofdeath)')
  Log.info('great artists steal: the stealable way to rock your dotfiles(tm)')
  Log.info('')

  # On Windows, we need to verify first that we are elevated.
  if platform.system() == 'Windows':
    try:
      subprocess.check_call('cmd /q /c at > NUL')
    except subprocess.CalledProcessError:
      Log.fail('You must run this script from an elevated command prompt.')
      Log.fail('Right-click cmd.exe and choose "Run as administrator".')
      sys.exit(1)

  Log.info('finding the symbol map')
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
    Log.fail(e.message)
    raise

  Log.success('completed reading the symbol map')
  operations = {pkg: process_package(pkg, symmap) for pkg in symmap}

  Log.info('analyzing...')
  try:
    check_dependencies(operations)
    numpkgs = len(operations)
    Log.success('finished checking %d package%s' %
        (numpkgs, 's' if numpkgs != 1 else ''))
  except ErrorAmalgam as e:
    Log.fail('giving up; %d errors encountered during analysis' % (
      len(e.error_list)))
    return None
  except Exception as e:
    Log.fail('an unexpected error occurred (this might be a bug)')
    Log.fail('please report this error message:')
    raise

  Log.info('situating dotfiles')
  try:
    perform_operations(operations)
  except ErrorAmalgam as e:
    numpkgs = len(e.error_list)
    Log.fail('%d package%s had errors' % (numpkgs, 's' if numpkgs != 1 else ''))
    return None
  except Exception as e:
    Log.fail('an unexpected error occurred (this might be a bug)')
    Log.fail('please report this error message:')
    raise

  Log.success('everything is OK!')
  return True

if __name__ == '__main__':
  main()
