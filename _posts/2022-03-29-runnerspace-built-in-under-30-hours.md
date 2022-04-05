---
layout: default
title:  Runnerspace, Built in Under 30 Hours
date:   2022-03-29 13:56:22 -0600
tags:   flask hackathon utsa rowdyhacks projects
_preview_image: https://raw.githubusercontent.com/Xevion/runnerspace/master/static/embed-banner.png
_preview_description: I attended Rowdy Hacks 2022 at UTSA, and while I can't say I left smiling, I did create a pretty cool project that I'd like to talk about.
---

I attended Rowdy Hacks 2022 at UTSA, and while I can't say I left smiling, I did create a pretty cool project that I'd like to talk about.

## Rowdy Hacks 2022

At Rowdy Hacks 2022, there were a couple tracks and challenges available to those attending; I'll skip telling you what
was available and tell you what we took - 'General' (the experienced developers) track and the 'Retro' challenge.

For our project, we initially started about making a tile-memorization game that would have a fast-paced MMO aspect
where players would compete to push each other out of the round by 'memorizing' sequences of information (like colored tiles).
Players would have health and successfully completing a sequence would lower other's health while raising your own,
almost like stealing health, but inefficiently (lossy vampire?).

We planned to do all of this with Web Sockets ran on FastAPI, although we pivoted to FastAPI for the backend when we
couldn't get web sockets to communicate properly. After 4 hours of fooling around and slow progress, we realized that
neither of us were game developers and that this project would not suffice.


## Runnerspace

[![/runnerspace/ Banner][runnerspace-banner]][runnerspace-github]

Our new plan was to create a retro social media site based on MySpace - it would use Flask for the frontend,
Sass (to make frontend development a little less painful), and SQLAlchemy as a database ORM. Furthermore, with Flask, 
Jinja2 is the standardized templating engine.

In the spirit of the Retro challenge, we made sure to style it like MySpace and other social media sites of the era.

We started at a slow pace, but eventually, we got on decently and were quickly beginning to make progress on the
frontend - which happened to be the major bottleneck. Given that our development time was limited and both of us were not
database modeling experts, we had to design out database around whatever the frontend ended up looking like.

Eventually though, after dozens of hours, we were able to come to a stopping point where the site was presentable to
judges. We submitted, got judged, and went through the rest of the Hackathon without too much sleep.
By the time I got home, I ended up going without sleep for 35 hours straight (from 8AM Saturday until 7PM Sunday) through 
the whole hackathon. Never have I ever been so tired in my life, but my peak exhaustion was not right before I went to 
sleep - in fact, it was in the hours preceding our project submission.

After waking up the next day, I began working on finishing the project in a way more suitable for a resume submission 
and portfolio project; the project in its current state was not deployable, it had a couple major issues and simply put -
it needed a lot more work before it was truly ready for presentation.

<center>The rest of this post will document Runnerspace's development.</center>

### Form Validation

Introducing *real* form validation into the project exposed a LOT of major issues with login, signup and other forms
that I had never thought of before; it's hard to say if some changes that it wanted were just paradigms I decided to
follow or not, but there were definite issues.

For example, passwords and usernames had absolutely no requirements on them!
A empty password was valid, spaces, unicode (emojis) and more were completely acceptable. when you're designing a webapp,
you never think about the millions of things users could do to mess with it, whether stupid or malicious.

In the process of form validation, I also ended up combining separate POST and GET routes into one - allowing GET and
POST methods at the same route. I had never thought of taking them at the same route for some reason, as if Flask 
wouldn't be able to handle it or something. I didn't do this for ALL my routes - I later ended up creating a `/post/{id}/like` route
to allow users to *like* a certain post; this request was sent through AJAX with jQuery; only POST requests were allowed 
on this route.

Combining POST and GET routes into the same `@route` function had more than a refactoring purpose; it allowed rejected forms
to be returned to the user properly! Displaying errors could now target specific fields!
At the same time, rendering these fields properly became rather complex; a macro function needed to be built in order to
make sure fields were consistent across the site.

{% raw %}
```jinja
{% macro render_field(field, show_label=True) %}
    {% if show_label %}
        {{ field.label }}
    {% endif %}
    {{ field(placeholder=field.description, **kwargs)|safe }}
    {% if field.errors %}
        <ul class=errors>
            {% for error in field.errors %}
                <li>{{ error }}</li>
            {% endfor %}
        </ul>
    {% endif %}
    <br>
{% endmacro %}
```
{% endraw %}

This code is a modified version from the WTF-Flask docs.

### Heroku Deployment

Heroku is a fantastic tool for cheap students or developers like me who don't wanna pay, but do want the project running.
Employers are not going to care that much about a branded domain, and they probably won't care about it taking 7-12 seconds to boot up,
but the fact that you could deploy it all and keep it running long term? That speaks volumes. Or at least, I hope it does. :P

And speaking of volumes, integrating a project with Heroku generates volumes of issues that one would never find in
development locally.

#### Flask, Postgres and Heroku

One of the first things you'll find with Heroku is that the drives your application runs on are 
<abbr title="Short lived, temporary">ephemeral</abbr> and anything written in run-time will not exist afterwards.

Some applications wouldn't mind this, but ours would, given that during development we ran our database ORM, SQLAlchemy,
off a local `.sqlite` file - a local file. This works great for our local developmnet purposes, but given that our
database should persist between dynos (effectively, different workers that work the Flask application) and restarts, it
would result in chaos and confusion if we actually ran with that.

So, my solution was to simply boot up a Heroku Postgres database, which luckily is completely *free* and can be setup
within seconds; additionally, SQLAlchemy supports many, many database types, including Postgres.

Additionally, Heroku provides the private URL for connecting to this database through environment variables, so
accessing it and integrating it's usage is quite easy; check the application's environment type variable to see if it's
running in `development` or `production`, and set the database URL accordingly.

Normally, that's it, but when I ran it for the first time, it errored: Heroku actually provides a different URL than
SQLAlchemy wants; SQLAlchemy wants `postgresql` for the protocol, but Heroku provides a URL with `postgres` instead. While
it once did support the latter, it no longer does. The solution? Simply using `.replace()` on the string to swap out the two.
Do make sure though to include the FULL protocol as the chance that some other part of the URL could contain `postgres` or
`postgresql` are slim, but not zero, and could result in a very, very confusing error if not. I also took advantage of the
`limit` parameter for `.replace()` as *extra* insurance.

```python
# Heroku deployment
if app.config['ENV'] == 'production':
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', '').replace('postgres://', 'postgresql://', 1)
```

Side-note: Do make sure to provide some kind of null-check or fallback for environment variable retrieval; it is possible the environment
variable could be un-configured and the `.replace` will fail on non-string values like `None`.

Lastly, with the protocol discrepancy solved, one would believe everything to be sorted out? Not quite; there is one last piece to go.

To connect to PostgreSQL databases, one actually needs to install a Pypi module; `psycopg2`, the most weirdly named module
I've ever seen that needed to be explicitly named and installed for a functioning application.

It seems the logic in including this was that if they included adapters for every type of database SQLAlchemy could work with, the dependency graph
would be huge and installing SQLAlchemy would add tons of modules and code that would *never* end up being ran, and worse,
could become failure points for applications which might only want to work with SQLite databases, like mine in the beginning.

#### spaCy Models

In the pursuit of making sure my application was safe to keep up indefinitely on Heroku and accessible to anyone, I wanted
to make it at least a little hard for people to post profanity on it; I wanted to spend as little time on this part of 
the app as possible while getting the most out of it. It turned out to actually be quite a searching frenzy to find a 
fully functional module on Pypi that would do this for me, but I eventually found something suitable.

Adding this to my application initially was quite easy; `pipenv install profanity-filter`
and then `pipenv exec python -m spacy download en`, and the module was ready to go. The module in total was surprisingly easy to use;
instantiate an object, then run text into a method and respond to the web request accordingly.

Later, I would end up building a WTForms validator to encapsulate profanity checks into a single function, which is another fantastic
reason for using WTForms (I am very happy with how WTForms works in Runnerspace). See below:

```python
class NoProfanity(object):
    def __init__(self, message: Optional[str] = None):
        if not message:
            message = 'Profanity is not acceptable on Runnerspace'
        self.message = message

    def __call__(self, form, field):
        if profanity.contains_profanity(field.data):
            raise ValidationError(self.message)
```

Based on how this works with `__call__`, you'd note that a function (or *lambda*) is a perfectly fine substitute,
but using an object lets one provide a custom message with your validators. I really like the pattern the documentation
showed me and would love to use it sometime again soon; perhaps other languages and projects could use something similar.

So, what went wrong? Disk persistence. In the process of getting Heroku to boot, it would completely fail to load the 
`profanity_filter` module! The `spaCy` models it needed did not exist. So, I found out that `spacy` provided pragmatic
methods to download models on the fly...

```python
if app.config['ENV'] == 'production':
        # Ensure spaCy model is downloaded
        spacy_model = 'en_core_web_sm'
        try:
            spacy.load(spacy_model)
        except:  # If not present, we download it, then load.
            spacy.cli.download(spacy_model)
            spacy.load(spacy_model)
```

But again - it didn't work. I submitted a discussion post asking for help, and they told me you need to restart the process
in order to use newly downloaded models.

So, I had to pivot to a different way to download the model. You may be wondering: why can't I download the model
through requirements.txt or something? Well, the thing is, I use `pipenv` *and* the model it needs is **not** hosted on 
PyPi!

So, I started looking into it - how do I get `pipenv`, which works with Heroku right out of the box, to download the
spaCy model for me? It turns out, it's quite straight-forward. `pip` can install packages directly from third-party URLs
directly using the same `install` command you'd use with `PyPi` packages.

Furthermore, `pipenv` does indeed support URLs [since late 2018][pipenv-direct-url-github-issue] and adding it
is simple as `pipenv install {url}`. So, that should work, right? It'll download the module, and it's even the smallest model version,
so there's not going to be any issues with [maxing out the tiny RAM][heroku-and-spacy-model-so] the hobby dyno is provided with, right?

Haha, no, it still doesn't work, and I never found out why. Additionally, the `profanity-filter` project is 
[abandoned and archived][profanity-filter-github] by its author.

So, to replace it, I simply started looking for a new package that had the same functionality without requiring some kind of
NLP text-processing module, and I eventually found [`better-profanity`][better-profanity-pypi]{: .no-underline}. It ended up being a 
drop-in replacement, although it seems to have fewer features *and* holes in its profanity detection. But, for now,
it's good enough.

## Conclusion

This project is hard to categorize as strictly either a waste of time, practice of skills I still have (kinda), or a 
genuine project for my resume. It's hard to say that I learned a bunch of new things, but I also didn't know or remember
half the issues I ran into with it. At the very least though, it has restarted my urge to improve my resume and continue
programming for the first time in months. I ended up putting down 120 commits in less than a week, and I'm still going.

If you'd like, [check out my project][runnerspace-heroku] and [leave a star for it on GitHub][runnerspace-github].
Bye.

[runnerspace-banner]: https://raw.githubusercontent.com/Xevion/runnerspace/master/static/runnerspace-banner-slim.png
[runnerspace-heroku]: https://runnerspace-utsa.herokuapp.com/
[runnerspace-github]: https://github.com/Xevion/runnerspace/
[better-profanity-pypi]: https://pypi.org/project/better-profanity/
[profanity-filter-github]: https://github.com/rominf/profanity-filter/
[pipenv-direct-url-github-issue]: https://github.com/pypa/pipenv/issues/3058
[heroku-and-spacy-model-so]: https://stackoverflow.com/a/70432019/6912830