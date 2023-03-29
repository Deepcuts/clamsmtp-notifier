# clamsmtp-notifier
clamsmtp-notifier


What it does 1: Notifies the final recipient if an email gets deleted by clamsmtp, but only if the recipient is managed by the server running the script.

What it does 2: Notifies the sender if an email gets deleted by clamsmtp, but only if the sender is managed by the server running the script.

Why: If an important email gets deleted, the user should know instead of waiting for that sweet seet cat pic in vain.

Requirements: clamsmpt, mailutils, a file with hosted domain names (one domain/line) and of course, a system set to delete emails if found infected.

How to enable: in your clamsmtp.conf add the line VirusAction: /PathToThis/script at the end of the file and uncomment it. 

Make the script executable and chown it to clamsmtp:clamsmtp

Tested on: Debian 11

TMP_LOC and LOG directories need write permission for clamsmtp user.

This script will try to create the LOG_DIR and set the correct permission if executed by a user with proper permissions.

This script will check if TMP_LOC is writeable. Best bet is to leave it as /tmp

This script will check for mailx command and trying to install it automatically if run with proper permissions.

Manually setup logrotate in case the logfile gets too big. Or hack the script and remove logging.

