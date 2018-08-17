# Regarding Setting Appropriate Expectations

A tool like Stat Watch can be a nightmare for an organization if appropriate expectations are not set with customers on how it should be used. It is the recommendation of the author of this project that when configuring Stat Watch to send customer facing emails, they are coupled with the expectation that the customer is the one responsible for determining whether or not a change to a file is a problem .Otherwise, it's likely that the customer will react to each email they receive by forwarding it on and expecting that someone else will make those assessments - and that's really not reasonable.

It is also the recommendation of the author of this project that any backups taken by Stat Watch not be mentioned to the customer. The backups taken by Stat Watch were intended to be a resource for the technician assisting the customer, and not one for the customer themselves.



## Examples of customer communication setting expectations for how emails from Stat Watch should be handled

Please note that while there might be instances where these examples could be used as-is, you should always review the contents to verify that they match what you intend to communicate to the customer. Feel free to use portions of them or use them in whole as matches your needs.

### Example email offering to put the script in place:

```
Dear Customer,

Given what we're seeing here, I think it would be beneficial to install a script on your server to monitor this directory and the files within for changes and email out reports on what has changed. This will help us gather the data we need to better investigate and future changes that might occur, and will also help us react more quickly if additional changes are made.

I do want to be clear, however, that if you give us the go-ahead to put this script in place, we will not be able to make judgment calls regarding the files that are reported as being new or modified. If you have assessed that a file from one of these reports is unwanted or has had unwanted changes made to it, we can definitely investigate further and attempt to assess how it was put in place or modified. We can also make adjustments to limit how frequently reports are sent or to specify that the script ignores changes to specific files or directories so that it is less likely to report any false positives. But we CAN NOT make assessments regarding whether or not any specific file is unwanted or malicious in nature - this is a determination that will have to be made on your end. Any requests for such an assessment will be rejected.

If you understand and are okay with this, I'll be happy to get this script set up for you. I will need the following information from you for this:

1) What's a good email address for us to have these reports sent to?

2) Typically we configure this script to run a check every two hours and only report if changes are detected. Let us know if you want this configured any differently.

I look forward to hearing back from you regarding this.
```



### Example follow-up email indicating that the script is in place:

```
Dear Customer,

I have put the script that I had mentioned in place as promised and configured it to run for the next 45 days. Let us know if you need us to exclude any specific files or directories from being checked due to them generating too many false positives.

Email messages from this script should arrive from the address root@[SERVER NAME] and have the subject line "Stat Watch - File changes on [SERVER NAME]". There is the potential that they will end up in your junk mail folder, so please be sure to check there. If you would like me to send a test message that you can reference, let me know and I will do so.

If there are any malicious or unwanted files that you would like for us to look into further, let us know and we can do so. I did want to state once again that we cannot make the assessment regarding whether a file is malicious or unwanted; that determination will need to be made by you or someone on your end.

If you have any questions or concerns that I can address, please don't hesitate to let me know.
```



### Example message for the top of each email message:

By modifying the files ./[JOB NAME]_message_head.txt and ./[JOB NAME]_message_foot.txt, you can add a message to the beginning or end (respectively) of each email Stat Watch sends. It's recommended that you add a message here as well to remind the customer of these expectations.

```
Hello,

This is an automated message from your server, sent by the script that we set up in ticket #[TICKET NUMBER] regarding the files that were being created in [DIRECTORY]. Please assess the changes listed below to see if they are anticipated or desired. If you determine that any of the files or changes to files listed here are unwanted, let us know (along with the details provided) and we can disable those files and investigate further in hopes of seeing what caused the change.

If you want us to exclude any files or directories from future checks in order to eliminate potential false positives, just let us know in ticket #[TICKET NUMBER] and we will be happy to make those changes for you.
```
