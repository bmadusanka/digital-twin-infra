# Black Duck Project Integrator

## The following script retrieves all the scans related to a project and puts them together as project childs from
## within a project that gathers all the repositories

import sys
from argparse import ArgumentParser
from blackduck.HubRestApi import HubInstance
import re
import pandas as pd
import json


def projectIntegrator(projectName, versionName, projectTags, userGroup):

  # Creating the instance to use Black Duck commands
  hub = HubInstance()

  # Getting all the projects in the Black Duck Server
  projectsDF = pd.DataFrame(hub.get_projects(limit = 15000)['items'])

  # Filtering those projects belonging to the current scanned repo
  filterConcat = projectName + "_" + versionName
  print(F"Filter used: {filterConcat}")
  filteredProjects = [val for val in sorted(list(projectsDF['name']))
    if re.search(re.compile(filterConcat), val)]
  print("List of projects matched:")
  print(filteredProjects)

  # Creating a Parent project for the filtered ones, adding the cap group
  main_project_release = hub.get_or_create_project_version("PARENT_" + projectName, projectName + "_" + versionName)
  hub.assign_user_group_to_project("PARENT_" + projectName, userGroup, "BOM Manager,Policy Violation Reviewer,Project Manager,Project Code Scanner,Security Manager")

  project = hub.get_project_by_name("PARENT_" + projectName)
  project_tags_url = hub.get_tags_url(project)

  print(projectTags.split(", "))

  for currentTag in (projectTags.split(", ")):
    print("Adding tag {} to project {} using tags url: {}".format(currentTag, project, project_tags_url))
    hub.execute_post(project_tags_url, {"name": currentTag})

  # Adding the projects to the parent
  for project in filteredProjects:
    versionsFromProj = pd.DataFrame(hub.get_project_versions(hub.get_project_by_name(project))['items'])

    for currVersionName in list(versionsFromProj['versionName']):
      sub_project_release = hub.get_project_version_by_name(project, currVersionName)
      hub.add_version_as_component(main_project_release, sub_project_release)

def main(argv=None):

  if argv is None:
      argv = sys.argv
  else:
      argv.extend(sys.argv)

  parser = ArgumentParser()
  parser.add_argument('projectName', help = "Name of the repository from which the projects will be searched")
  parser.add_argument('versionName', help = "Version of the project used to complement the project name")
  parser.add_argument('projectTags', help = "Tags to be added to the PARENT project")
  parser.add_argument('userGroup', help = "User group to which the project will be assigned")
  args = parser.parse_args()

  print(args)

  if (not args.projectName)|(not args.versionName):
      parser.print_help(sys.stdout)
      sys.exit(1)

  projectIntegrator(args.projectName, args.versionName, args.projectTags, args.userGroup)

if __name__ == "__main__":
  sys.exit(main())
