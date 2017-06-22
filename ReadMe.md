# DataPlatform Automated Upgrade

Automated upgrades were introduced in DataPlatform Runtime Framework version > 24.5.1 in an effort to promote better usability, replace manual processes, stop/mitigate “breaking” changes in Framework releases and to streamline the update experience overall.

Anyone working with the DataPlatform knows that it is updated regularly. It’s a fact of modern life, everyday brings slack notifications that DataPlatform Framework Version 26.y.z is ready, Ontology 3.y.z wants to be installed and you need version 2.y.z of FHIRWalker RIGHT NOW.

_"In the world of software management there exists a dread place called "dependency hell." The bigger your system grows and the more packages you integrate into your software, the more likely you are to find yourself, one day, in this pit of despair.""_		– Tom Preston-Werner


### Breaking Changes
In the unlikely event, that there are breaking changes, [**we**<--who is this?] stop the script. The team whose build is broken gets the opportunity fix it, and then the upgrade is kicked off from where it had previously stopped. If the build breaks there is not an option to roll back. The procedure simply continues down the decision tree workflow. As things stand, it’s not clear if you can fall back to an older Framework installation by doing a new, from-scratch reinstall using your original repo.

[**QUESTION:** Lastly, I'm not sure how the automated upgrade gem will handle breaking changes - could use more detail (which may not have been worked out yet by plasma) about breaking changes and how these will be distributed to teams to change their code in accordance with these changes. This also goes for Team City configuration changes and settings/org-tenant changes that may need updating when a new framework is released.]


## Overview

Automated Upgrades brings all your upgrades together in one place. It's real-time upgrading based on the project or service dependency tree for DataPlatform teams. We're on a mission to make your working life simpler and more productive.
Automated Upgrades is a [ruby gem][2] that can be included within a ruby script. This gem enables developers to test a full end-to-end dependency tree upgrade locally as well as a partial-tree upgrade test. This same "gem in a script" can be used to run the upgrade cycle in TeamCity.

**Automated Upgrades encapsulates two processes:**

- A NuGet update
- A TeamCity deploy build for DataPlatform’s existing or dependent services
which both use a manifest file as their roadmap.

The manual NuGet update uses the manifest file to do this thing

The TeamCity build uses this same manifest file and is triggered by a successful DataPlatform Runtime build completion via the master branch in GitHub. The develop branch is used for pre-release NuGet packages.

[The above paragraph has this revision: **QUESTION:** I believe that the process will begin when DataPlatform Framework is checked into master, rather than develop since plasma releases are in the master branch and develop is used for prerelease packages. The same goes for other teams who release nuget packages.]

The process is considered complete when existing and dependent services finish deployment and automated User Acceptance Tests (UATs) are kicked-off.

Automated upgrades allows manual intervention for cases such as breaking code and configuration changes, and also allows interrupt and restart at any point in the process, so you are able to modify as necessary.

[**QUESTION:** Also, I'm unsure about the flow with upgrading locally vs upgrading in Team City and the nuget packages. Does this mean that whenever a project upgrades with lower dependencies, whoever has checked it will upgrade and build the other services before pushing to the develop or master branch? That can probably be answered by someone in plasma, since they're working on the flow. ]

Automated Upgrades encapsulates a manual Nuget update and TeamCity deploy kickoff for DataPlatform’s Existing or Dependent services based on a manifest file. It ends when dependent services finish deployment and automated UATs are kicked off.

Automated upgrades allows manual intervention for cases such as breaking code and configuration changes, and also allows interrupt and restart at any point in the process, so you are able to modify as necessary

## Projects & Components

This repository holds all artifacts: design, code and supporting files that go into creating a solution for automated upgrades and deployment of services against a chosen DataPlatform Framework [Runtime?] version.

## How does it work?

The automated upgrade project is dependent on DataPlatform teams first adding 
`.semvers` files to each project. This allows for the automation process to kickoff the following workflow.

![automated_upgrade_flow][3]

Once the Runtime Build has successfully completed, the **upgrade project** is triggered in TeamCity and begins the following steps:

1. The gem extracts a version map (JSON file) of packages of DataPlatform Projects and nuget versions from the [.semvers][4] files.
2. Once the version map is extracted, it compares itself to a previous version map for changes. If there are changes, it walks the deployment project dependency tree to process the upgrade according to the dependency chain manifest.
	- If there aren't changes, the gem triggers the _existing?_ TeamCity chain of deployments. **[Projects that build and deply nugets must be exempted(?).]** If the script runs to completion without errors, we assume success and consider it validated.
         -  Trigger acceptance tests
         -  Reset project completion status to unprocessed for all
         -  push updated manifest
         -  end
3. It next seeks what is the next project in the dependency tree in a failed or unprocessed state? [how does it choose, via alphabetical, numberical or our logical progression, of first this team, then that team, etc.?] If a project has indeed failed, or is in an unprocessed state:
    - The gem looks for the Project's environment variables. If there are no environment variables or if they have incorrect file names, the process fails and exits  [Does it provide any --verbose message?]:
    
    **EXAMPLE:** 
    ``` 
    Failed, wah-wah: frameworkweb.semver), filename should be Framework.Web.semver
    ``` 
   
4. If your project has valid Environment vaiables, it first checks:
   - Does the branch exist? If so, the gem checks out the source and specified branch. 
   - If not, service [<--what do you mean by Service here?] derives an upgrade branch from a specified branch. (automagically or manually?)
5. If your project's `semver` file matches special/nonspecial [<--what consitutes being *special?*]
 	- If no, dependency walk is complete, trigger acceptance tests.
6. Run nuget package version update for specific changed DataPlatform package.
[**QUESTION:** step 6 "execute nuget", references the deployment of nuget packages, which requires the TC build to run and execute unit and integration tests, as well as BVTs. This would happen in the middle of each upgrade for each service on TeamCity and before Acceptance Tests would build. So I think this step would be encapsulated in previous step]
7. Does project a. build and b. publish nuget? or does the built project publish the Nuget successfully? or is this a project that publishes NuGets?
   - If yes, increment the [.semver] <--minor, major? [link to semver doc here]
   - **If no, do the below, but no version update? why not? what's different? this scenario goes to fail message without .semver info** 
   - After the .semver file is updated, set [<--set where? why? ]the project environment variables.
8. Gem checks? TeamCity checks? DevOps checks to see if the build is successful or has test faillures.
  - Success: Commit version updates and .semver changes with standard message or success message?
  - Failure: Commit version updates and .semver changes with failure message.
9. Checkout and rebase specified branch with upgrade branch. (what if rebase fails?)
10. Push rebased branch, delete "upgrade branch" (both locally and remotely) if pushed. (what if delete local/remote fails? duplication?)
  - **Push failed**? (commit history has diverged)
    - Upon Push failure, pull rebase specified branch (automagically or manually?)
    - Update manifest with project status marked as failed, allowing for manual intervention.
    - Email stakeholders of failure notification (can we slackbot the build?). Who is the first-responder? Project Team? DevOps? PMs?
    - Push updated manifest to where? Assume this is all failures and successes?
11. Gem checks to see if (what?--project or specific file (s)?) has a Configuration change.
  -  If a configuration has changed, it runs a settings/cloud service update for the Service. What file(s) are modified? JSON, `app.config`?
12. If configuration is successful it triggers a TeamCity build. If update of configuration fails... 
  - need failure scenario here.
13. Upon successful TeamCity Build, (again check to see)? if NuGet is published by project.
  - Success: Save updated nuget information and walk deployment project dependency tree to process upgrade per newly updated manifest.
  - Failure: TeamCity has failed, investigate cause and reinitiate from what point?
14.  Now what? : )  Assumption, we have a manifest with success and failures...

##### Generate Version Map
The script first generates a version map, which lists all package version references from DataPlatform Runtime solution must be generated. This list can go into a shared repository that has other artifacts to be used for the upgrade cycle like dependency map, configuration manifest etc.

##### Upgrade Repo locally
A single repository is version upgraded. At this time, nugets are not published, and no branches are pushed. Should run partial tree?

##### Upgrade a repo on build server
Q: How does the process handle new services that are added?
A: New services can be added by updating the manifest.
When started from a Teamcity project, a single repo will be upgraded. Either the service or a NuGet publishing project.
Q: Does upgrade all only include EME services or will it impact Pop Manager and DDA Extract?

A: This will include any service currently being built on TeamCity and using the DataPlatform.

##### Upgrade all based on dependency tree

You can subscribe to any app's what?

## Scheduled upgrades?

Yes, upgrades can be scheduled in [TeamCity][5].

## Which apps?

Rake? (used for building data platform)
This repository holds all artifacts - design, code and supporting files that go into creating solution for automated upgrade and deployment of services against chosen framework version
- [Azure PowerShell 0.9.8.1](https://github.com/Azure/azure-PowerShell/releases)or just the script?
- [Ruby 2.0.0-p481 (32-bit)][6]
- [Access to the unsecured gem source](http://ndhaxpgit01.mckesson.com/Carnegie/Documentation/wiki/Versions-Script#step-1-add-the-unsecured-http-gem-source)
**Ruby Gems:** Can we add pessimistic version constraint syntax?
```
gem "cucumber", ">=0.8.5", "<0.9.0"
```
-   [addressable][7] (2.4.0)
-   [nokogiri ][8] (1.6.5)
-   [semver2][9] (3.3.3)

##  Relevant coding conventions

-   Ensure that tab space in your text editor is set to 2, which is the default for Ruby.
-   If using Sublime Text 3, use the [BeautifyRuby][10] package and setup settings to use 'Beautify on Save'. In the  **Preferences** menu --> Package Settings --> BeautifyRuby --> Settings - Default, add the following:
PowerShell Scripts run by the Gem
-   Put C sharp info here?
-   Ruby based 	


### Developing with Ruby

-   Ensure tab space in editor is set to 2
```
    "translate_tabs_to_spaces": true,
    "tab_size": 2
```
- If using Sublime Text 3, use [BeautifyRuby][5] package and setup settings to use 'Beautify on Save'. Go to Preferences menu --> Package Settings --> BeautifyRuby --> Settings - Default and add the following
- Avoid using return statements when returning values from methods. The last variable in method is returned

```

    def test
        s = "A String"
        s # not return s
    end

    def comparer valA, valB
        valA + 2 < valB # no need for return in front
    end

```

-   When catching exceptions use `puts $!` to display full exception
-   Use `p [variable]` to display object and it's internals. `puts [variable]` only displays toString version
-   Use double quotes for strings only if one or more variables are being interpolated
-   Call methods with params, create methods with params without braces as much as possible
-   To run all tests, change to src\ folder and run `rake test`
-   To run tests individually: `ruby.exe .\spec\upgrade_spec.rb -n test_fail_on_missing_env_vars`
-   Ruby gems required - addressable (2.4.0), nokogiri (1.6.5), semver2 (3.3.3)

##  Development / testing environments

-   To run all tests, change directories `cd` into src\ folder and run `rake test`
-   To run tests individually: `ruby.exe .\spec\upgrade_spec.rb -n test_fail_on_missing_env_vars`
-   Updated tests, begin update all

##  Additional Resources

More information to come.

[1]: http://tom.preston-werner.com/
[2]: https://rubygems.org/
[3]: http://ndhaxpgit01.mckesson.com/SureshBatta/AutomatedUpgrade/raw/master/design/automated_upgrade_flow.png
[4]: http://semver.org/
[5]: https://packagecontrol.io/packages/BeautifyRuby
[6]: https://confluence.jetbrains.com/display/TCD8/Configuring+Schedule+Triggers
[7]: http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p481.exe
[8]: https://rubygems.org/gems/addressable/versions/2.4.0
[9]: https://rubygems.org/gems/nokogiri/versions/1.6.5
[10]: https://rubygems.org/gems/semver2/versions/3.3.3
[11]: https://packagecontrol.io/packages/BeautifyRuby
