# YAML files parser for repositories to pip install script

## The following script receives the location of a yaml file containing a list of repositories with their related metadata (e.g. revision),
## and then converts them into a script that can be run to clone all those repositories.

import sys
from argparse import ArgumentParser
import yaml

def scriptGenerator(yamlLocation):
  with open(yamlLocation, 'r') as f:
    repos = yaml.full_load(f)

  with open('script_cloning.sh', 'w') as fp:
    for i in (repos['repos']):
      if i['repo'] != "local":
        print(i['repo'] + ": " + i['rev'])
        fp.write("git clone -b " + i['rev'] + " " + i['repo'] + "\n")

def main(argv=None):

  if argv is None:
      argv = sys.argv
  else:
      argv.extend(sys.argv)

  parser = ArgumentParser()
  parser.add_argument('yaml_location', help="Relative or absolute address where the yaml file with the repositories is located")
  args = parser.parse_args()

  print(args)

  if (not args.yaml_location):
      parser.print_help(sys.stdout)
      sys.exit(1)

  scriptGenerator(args.yaml_location)

if __name__ == "__main__":
  sys.exit(main())
