# Ender Registry
A ComputerCraft ecosystem to manage Ender Storage chest colours.

### About
Ender Registry is a multi-project ecosystem that utilizes the ComputerCraft UI framework [Titanium](https://gitlab.com/hbomb79/Titanium/) for ender chests management.
The widely used Ender Storage mod for Minecraft links chests together with colour patterns.
It becomes rather tedious to keep track of which colour patterns are used for what and by whom on a larger server.
Ender Registry aims to solve this problem by providing easy to use interfaces for players to add colour patterns with descriptions.
The ecosystem consists of three parts: Ender Registry Master, Ender Registry Client and Ender Registry Display.

#### Ender Registry Master
This is the master console behind the entire system and handles requests for adding new entries as well as checking whether a given colour combination exists already.
It will keep track of all existing entries in a scrollable list and provide a simple log to see which entries were added/deleted.

![](https://i.imgur.com/Wr3PSMf.gif)

#### Ender Registry Client
The registry client allows players to register new colour patterns.
The interface guides the player through a series of steps to fill in the details of their new entry.
New colour combinations are verified against the registry master to prevent duplicate entries.

![](https://i.imgur.com/MRdjqm6.gif)

#### Ender Registry Display
Program to display all entries of the registry on a multi-block monitor.
Will show the name, colour pattern and description of each entry in a scrollable container.
The display will periodically update with new entries by querying the master registry.

![](https://i.imgur.com/13s3l5v.png)

### Build
As mentioned before, the ender registry projects use the [Titanium](https://gitlab.com/hbomb79/Titanium/) UI framework.
The projects can be best build using the Titanium Developer Tools (TDT).
The step-by-step guide below covers how to install TDT and build the projects, which is mostly the same for each project.

#### Installing TDT
The Titanium Developer Tools are the quickest way to get the projects built and running.
TDT can be installed, along with Titanium Package Manager (TPM) and packager, using `pastebin run 5B9k1jZg`.
This will prompt you to add the `bin` folder of TPM to the path, which is recommended to quickly access the commands.

#### Configuring the projects
For each of the ender registry projects, you will need to create a corresponding project using TDT.
For the sake of brevity we will go over the steps for Ender Registry Master.
The steps for the other projects are identical by substituting their respective names.

- Create a new project using TDT: `tdt new RegistryMaster`
- Create a new directory for Ender Registry Master on the computer: `mkdir registry-master`
- Move the files from this repo into the directory you just created
- Add the source file to the TDT project: `tdt add registry-master/src/main.lua`
- Add the UI directory as extract files: `tdt add-extract registry-master/ui`
- Set the init property in the TDT settings: `tdt set init registry-master/src/main.lua`
- Set the output property in the TDT settings: `tdt set output EnderRegistryMaster`

#### Build the projects
Now that you have configured the projects for the Ender Registry, we can build and run them.
Executing `tdt build` will build the currectly open project and `tdt run` will run it.
After a successful build, you can also distribute the output file (for example `EnderRegistryMaster`) to other computers that don't have TDT installed.
