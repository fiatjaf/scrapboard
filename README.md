# scrapbook

A decentralized couchapp implementation of the old Orkut Scrapbook.

## background

[Orkut](https://orkut.google.com/en.html)'s **Scrapbook** was a messaging service that allowed public _scraps_ (a text message) to be posted by anyone to anyone's _scrapbook_.

Although simple, the Scrapbook was a somewhat unique messaging service for a social network. It worked as a hybrid between private messaging and publicly posting, for example, on a friend's Facebook Timeline. But, unlike private messaging, unlike posting to a friend's Timeline and unlike sharing content with everybody and at the same time with no one (as with Twitter), in the Scrapbook:

* the content was public;
* the content was directed to someone;
* the posted content wasn't mixed with totally unrelated contents (in a Twitter or Facebook stream, for example);
* the posted content wasn't perishable;
* the posted content wasn't streamed to anywhere, so it wasn't a big deal to send someone a scrap, it would not be shown to a lot of unrelated people, except if they went looking after it;

These apparently simple features

* encouraged quick message exchanges, regarding any subject, big or small, even between strangers;
* allowed people to include themselves in others' conversations, if the theme interested them and they happened to see it;
* encouraged public discussion of themes that, at first, could be seen as unworthy, because they were not being displayed at everyone's computers, they were shown just to the interested people.

## the decentralized approach

Since no one here is willing to create another abandoned social network wannabe, **Scrapbook** was implemented in a way everyone can have their scrapbook as a single page app, accessible through a URL or embeddable as an iframe or a Javascript widget.

When sending scraps to others', the user is faced with the possibility of writing its own scrapbook URL or just his name. This allows for a verification step, done automatically by the scrapbook owner whenever he logs in, in which he checks the scrapbook URL left at his scrapbook for the existence of a copy of that same scrap. If the user lefts only his name, or nothing at all, the scrap is sent anyway, but it can never be verified -- except manually by the scrapbook owner --, but this is also good, since it allows people to use their scrapbook for getting message from others (or even replying in his own scrapbook) while they still don't have one.

## installation

You can deploy your own Scrapbook using `git clone`, `npm install`, the compilation scripts at package.json and uploading with [erica](https://github.com/benoitc/erica) or [couchapp](https://github.com/couchapp/couchapp). Before deploying, create a `settings.json` file containing

```javascript
{
  "hashcash": "asio3u4h-a-random-string-345oin54",
  "baseURL": "http://scrapbook.mycouch.com/",
  "hosts": [
    "some.domain.where.you.are.embedding.the.scrapbook.as.a.widget"
  ]
}
```

Only the `baseURL` is necessary. It should point to the URL from which you'll be accessing your scrapbook, after \_rewrites and vhosts magic (which you should do).

For improved spam safety, in your `_security` configuration for the Scrapbook database, add yourself as the sole Admin name and a role named "anti-abuse". This will enable a hashcash requirement for every scrap you'll receive.

---

We are working on a non-geek easy and free installation for [Smileupps](https://www.smileupps.com/store/apps/scrapbook).
