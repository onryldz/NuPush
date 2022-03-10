# NuPush
Nuget Package Push Manager (cli)

This package helps to manage your nuget versions easily. When you have many projects under a solution, you can see each project and current version of it. 
Steps:

1- You need to add this `powershell`/`bash` script’s path in your environment variables.

2- Open a terminal on your windows, and go to the your project solution folder and write `nuPush` then press enter.

3- You will see all of the project list with the version

4- You can select a project which you will push to your nuget repository.

5- Then you will see the nuget source list

6- When you select the nugget source, it will start to upload it.

### Linux/Debian Instructions
* You need to edit the `~/.bashrc` file to permanently add environment variables. Add this command to the last line.
  - `export PATH=$PATH:nupushPathOnYourComputer` *(e.g. export PATH=$PATH:$HOME/dev/nuPush)*
  - You have to execute this command to run the unit test.
    * `export NUPUSH_RUN_UNITTEST="true"`
* `sudo chmod +x nuPush`
