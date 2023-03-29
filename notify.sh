#!/bin/bash

##################################################################################################################################################################
# Name: clamsmtp-notifier-script
# Date: 30 March 2023
# by: INTEQ (tech@inteq.ro)
# What it does 1: Notifies the final recipient if an email gets deleted by clamsmtp, but only if the recipient is managed by the server running the script.
# What it does 2: Notifies the sender if an email gets deleted by clamsmtp, but only if the sender is managed by the server running the script.
# Why: If an important email gets deleted, the user should know instead of waiting for that sweet sweet cat pic in vain.
# Requirements: clamsmpt, mailutils, a file with hosted domain names (one domain/line) and of course, a system set to delete emails if found infected.
# How to enable: in your clamsmtp.conf add the line VirusAction: /PathToThis/script at the end of the file and uncomment it. 
# Make the script executable and chown it to clamsmtp:clamsmtp
# Tested on: Debian 11
# TMP_LOC and LOG_DIR directories need write permission for clamsmtp user.
# This script will try to create the LOG_DIR and set the correct permission if executed by a user with proper permissions.
# This script will check if TMP_LOC is writeable. Best bet is to leave it as /tmp
# This script will check for mailx command and trying to install it automatically if run with proper permissions.
# Manually setup logrotate in case the logfile gets too big. Or hack the script and remove logging.
##################################################################################################################################################################

### Setup variables begin ###

# Return the hostname from hostname command or manually set without ``
EMAIL_SYS_NAME=`hostname`
# The email to send the notification from
FROM_EMAIL=postmaster@domain.com
# The email to CC, like the domain admin. Leave emtpy to not send a CC notification
TO_ADMIN= # leave empty to not notify admin also
# Notification email subject
SUBJECT_EMAIL="=?utf-8?Q?=E2=9A=A0?= Warning: Malware found in an email"
# File containing the list of domains hosted on this server. One domain per line. Need read permission for user running theis script
DOMAINS_FILE=/etc/dkim-domains.txt
# Email address in notification responsible for security and troubleshooting.
HELPDESK_EMAIL=helpdesk@domain.com
# Directory for logs
LOG_DIR=/var/log/clamsmtp
# Log file name
LOG_FILE=$LOG_DIR/notify.log
# Temporary directory to create notifications. Files get deleted after sending.
TMP_LOC=/tmp
# User running this script
CLAMSMTPUSER=clamsmtp
# Group for the user runnign this script
CLAMSMTPGROUP=clamsmtp

### Setup variables end ###


# Check if dependencies are met. Will try to install automatically mail.
# WARNING: Only debian compatible (apt). Modify to suit your operating system.
# Comment the next line to disable checking.
type mailx >/dev/null 2>&1 || { echo >&2 "This script requires mailx, but it's not installed. Trying to install now..."; DEBIAN_FRONTEND=noninteractive apt install mailutils -y -qq < /dev/null > /dev/null; }

# Checking if required directories exist and are writeable.
# Run this script manually 1st time to create the log folder and assign the correct permission. Or do it manually.
if [ ! -d "$LOG_DIR" ]; then
    echo "$LOG_DIR does not exist. Trying to create it now"
    mkdir $LOG_DIR
    chown -R $CLAMSMPPUSER:$CLAMSMTPGROUP $LOG_DIR/
    [ ! -w "$LOG_DIR" ] && printf "!!!ERROR!!!\nDirectory $LOG_DIR is not writable. Aborting..." && exit 1
    [ ! -w "$TMP_LOC" ] && printf "!!!ERROR!!!\nDirectory $TMP_LOC is not writable. Aborting..." && exit 1
    echo "Script halted"
    exit 0
fi

# Start logging to file when an email gets deleted by clamsmtp

echo "-------------------------------------------" >> $LOG_FILE
echo "Malware $VIRUS detected on $(date)" >> $LOG_FILE
echo "Remote server $SERVER" >> $LOG_FILE
echo "Sender $SENDER" >> $LOG_FILE
echo "Recipient(s): $RECIPIENTS" >> $LOG_FILE

# If a virus is found in an inbound email send to one of the domains hosted on this server
# For every recipient, do a check
for rcpt in $RECIPIENTS; do

# Check $DOMAINS_FILE to match recipient with hosted domains.
for doms in `cat $DOMAINS_FILE`; do

# Check if recipient email address contains a domains hosted by this server.
# We do not want to send notifications to email accounts not hosted on this server
case "$rcpt" in 
    *$doms*)

echo "Sending notification to $rcpt" >> $LOG_FILE

# Create a unique tempfile. clamsmtp user should have write access to the TMP_LOC folder
TMP_FILE=$TMP_LOC/clamsmtp_notifier$RANDOM.txt
while [ -f $TMP_FILE ]; do
TMP_FILE=$TMP_LOC/clamsmtp_notifier$RANDOM.txt
done

# Creating notification content
echo "" >> $TMP_FILE
echo "" >> $TMP_FILE
echo "This is the email system at $EMAIL_SYS_NAME" >> $TMP_FILE
echo "" >> $TMP_FILE
echo "An attachment in an email from $SENDER was infected with malware ($VIRUS)." >> $TMP_FILE
echo "The email was deleted and will not reach your inbox." >> $TMP_FILE
echo "" >> $TMP_FILE
echo "If this email is important and you know the person at $SENDER, forward this email to $HELPDESK_EMAIL ." >> $TMP_FILE
echo "If this email was actually send by you to someone else, scan the file(s) you previously attached at https://www.virustotal.com ." >> $TMP_FILE
echo "Forward this email to $HELPDESK_EMAIL if the file(s) are not detected as malware." >> $TMP_FILE
echo "" >> $TMP_FILE
echo "Malware detection is not always 100% accurate. Some attachments might be falsely flagged." >> $TMP_FILE
echo "" >> $TMP_FILE
echo "" >> $TMP_FILE
echo "Details:" >> $TMP_FILE
echo "Detected malware: $VIRUS" >> $TMP_FILE
echo "Sender: $SENDER" >> $TMP_FILE
echo "Recipient: $rcpt" >> $TMP_FILE
echo "Date: $(date)" >> $TMP_FILE
echo "Server: $EMAIL_SYS_NAME" >> $TMP_FILE

# Sending a notification only to recipient(s) hosted on this system.
cat $TMP_FILE | mailx -a "From: $FROM_EMAIL" -r "$FROM_EMAIL" -s "$SUBJECT_EMAIL" $rcpt,$TO_ADMIN

# Deleting the temporary file
rm -f $TMP_FILE

# Continue with next recipient
break
esac
done
done


# If a virus is found in an outbound email send from one of the domains hosted on this server
# For sender, do a check
for sndr in $SENDER; do

# Check $DOMAINS_FILE to match sender with hosted domains.
for doms in `cat $DOMAINS_FILE`; do

# Check if sender email address contains a domains hosted by this server.
# We do not want to send notifications to email accounts not hosted on this server
case "$sndr" in 
    *$doms*)

echo "Sending notification to $sndr" >> $LOG_FILE

# Create a unique tempfile. clamsmtp user should have write access to the TMP_LOC folder
TMP_FILE=$TMP_LOC/clamsmtp_notifier$RANDOM.txt
while [ -f $TMP_FILE ]; do
TMP_FILE=$TMP_LOC/clamsmtp_notifier$RANDOM.txt
done

# Creating notification content
echo "" >> $TMP_FILE
echo "" >> $TMP_FILE
echo "This is the email system at $EMAIL_SYS_NAME" >> $TMP_FILE
echo "" >> $TMP_FILE
echo "An attachment in an email from $SENDER was infected with malware ($VIRUS)." >> $TMP_FILE
echo "The email was deleted and will not reach your inbox." >> $TMP_FILE
echo "" >> $TMP_FILE
echo "If this email is important and you know the person at $SENDER, forward this email to $HELPDESK_EMAIL ." >> $TMP_FILE
echo "If this email was actually send by you to someone else, scan the file(s) you previously attached at https://www.virustotal.com ." >> $TMP_FILE
echo "Forward this email to $HELPDESK_EMAIL if the file(s) are not detected as malware." >> $TMP_FILE
echo "" >> $TMP_FILE
echo "Malware detection is not always 100% accurate. Some attachments might be falsely flagged." >> $TMP_FILE
echo "" >> $TMP_FILE
echo "" >> $TMP_FILE
echo "Details:" >> $TMP_FILE
echo "Detected malware: $VIRUS" >> $TMP_FILE
echo "Sender: $SENDER" >> $TMP_FILE
echo "Recipient: $rcpt" >> $TMP_FILE
echo "Date: $(date)" >> $TMP_FILE
echo "Server: $EMAIL_SYS_NAME" >> $TMP_FILE

# Sending a notification only to recipient(s) hosted on this system.
cat $TMP_FILE | mailx -a "From: $FROM_EMAIL" -r "$FROM_EMAIL" -s "$SUBJECT_EMAIL" $sndr,$TO_ADMIN

# Deleting the temporary file
rm -f $TMP_FILE

# Continue with next sender
break
esac
done
done

return 0
