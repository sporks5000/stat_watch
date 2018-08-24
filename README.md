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
cd ~/
git clone https://github.com/sporks5000/stat_watch.git
chmod +x ~/stat_watch/stat_watch.pl ~/stat_watch/stat_watch_wrap.sh # This one probably isn't necessary
~/stat_watch/stat_watch.pl --help
```

Stat Watch does have options that allow for checking the MD5 sums of files as well. In order to test that all requirements of this functionality are present you can run the following:

```
~/stat_watch/stat_watch.pl --md5-test
```

For ease of use, you can symlink this to a location within your $PATH variable, or create an alias for it:

```
ln -s ~/stat_watch/stat_watch.pl ~/bin/stat_watch.pl
echo -e "\nalias statwatch='~/stat_watch/stat_watch.pl'" >> ~/.bashrc
```

### Updating

If you need to update to a newer version:

```
cd ~/stat_watch/
git pull origin master
cd ~/
```

### Command Line Options

#### General Usage for stat_watch.pl
(see "--help" output for more details)

```
./stat_watch.pl --record [DIRECTORY] ([DIRECTORY 2] ...)
    - Creates a Stat Watch report of all of the files within the directories specified (and the subdirectories thereof) including their current stat data
    - See the full "--help" output for more information on this

./stat_watch.pl --diff [REPORT FILE 1] [REPORT FILE 2]
    - Compare two Stat Watch report files, weed out files that match ignore rules, output information on what has changed
    - See the full "--help" output for more information on this

./stat_watch.pl --backup [REPORT FILE]
    - Create backups of files specified using a Stat Watch report file
    - There are options for selecting what should and should not be backed up
    - See the full "--help" output for more information on this

./stat_watch.pl --list [FILE]
    - This will list the available backups that Stat Watch has taken of a specific file

./stat_watch.pl --prune [FILE]
    - Go through the backup directory and remove files older copies of files
    - See the full "--help" output for more information on this

./stat_watch.pl --md5-test
    - Test to see if everything necessary is in place for checking the md5sum of files

./stat_watch.pl --help
    - Outputs full help information

./stat_watch.pl --version
    - Outputs version and changelog information
```

#### General Usage for stat_watch.pl
(see "--help" output for more details)

```
./stat_watch_wrap.sh
    - Asks the user key questions in order to create a Stat Watch job file with the information necessary to watch and backup key user files
    - See the full "--help" output for more information on this

./stat_watch_wrap.sh --run [JOB FILE]
    - Runs the necessary commands to complete a Stat Watch job, including checking the stats of files, determining th edifferences, and backing up files when necessary
    - See the full "--help" output for more information on this

./stat_watch_wrap.sh --email-test [EMAIL ADDRESS]
    - Sends a test message to the email address specified so that the end recipient can see an example

./stat_watch_wrap.sh --help
    - Outputs this text

./stat_watch_wrap.sh --version
    - Outputs version and changelog information
```

### Feedback, etc.

Any errors, unexpected behaviors, comments, or feedback can be reported at the github repository page.

