## Stat Watch

Processes and workflows for watching stat data on files and directories in order to better recognize changes that have been made

### Requirements

Stat Watch is designed to be run on Linux. It was designed with CentOS and cPanel in mind as the environment, but there is no reason why it shouldn't be able to run in any Linux environment.

The Stat Watch project is written in Perl and Bash; interpreters for both of these will be necessary for full functionality.

stat_watch.pl relies on the following external binaries present on the majority of Linux systems: stat, diff

stat_watch_wrap.sh relies on a number of standard GNU programs, as well as having a mail binary that provides functionality similar to that seen with heirloom mailx for the functionality of sending email alerts.

### Installation

Run the following commands:

```
cd /usr/local/src
git clone https://github.com/sporks5000/stat_watch.git
stat_watch/install.sh
stat_watch --help
```

Be default, the installation script will create a symlink at '/root/bin/stat_watch'.

Stat Watch does have options that allow for checking the MD5 sums of files as well. In order to test that all requirements of this functionality are present you can run the following:

```
~/stat_watch/stat_watch.pl --md5-test
```

### Updating

Updating to a more recent version can be accomplished with the installation instructions.

### Command Line Options

#### General Usage for stat_watch.pl
(see "--help" output for more details)

```
stat_watch --record [DIRECTORY] ([DIRECTORY 2] ...)
    - Creates a Stat Watch report of all of the files within the directories specified (and the subdirectories thereof) including their current stat data
    - See the full "--help" output for more information on this

stat_watch --diff [REPORT FILE 1] [REPORT FILE 2]
    - Compare two Stat Watch report files, weed out files that match ignore rules, output information on what has changed
    - See the full "--help" output for more information on this

stat_watch --backup [REPORT FILE]
    - Create backups of files specified using a Stat Watch report file
    - There are options for selecting what should and should not be backed up
    - See the full "--help" output for more information on this

stat_watch --list [FILE]
    - This will list the available backups that Stat Watch has taken of a specific file

stat_watch --create
    - Asks the user key questions in order to create a Stat Watch job file with the information necessary to watch and backup key user files
    - See the full "--help" output for more information on this

stat_watch --run [JOB FILE]
    - Runs the necessary commands to complete a Stat Watch job, including checking the stats of files, determining the differences, and backing up files when necessary
    - See the full "--help" output for more information on this

stat_watch --md5-test
    - Test to see if everything necessary is in place for checking the md5sum of files

stat_watch --help
    - Outputs help information

stat_watch --version
    - Outputs version and changelog information
```

### Feedback, etc.

Any errors, unexpected behaviors, comments, or feedback can be reported at the github repository page.

