# FossilHub Demo Dig

This is a real Fossil repository created by the FossilHub container on its
first start. Source, documentation, wiki pages, tickets, forum posts, and their
histories all live in the single persistent `dig.fossil` artifact.

The FossilHub landing and catalogue pages preserve the supplied visual
prototype. Repository operations are handled by Fossil itself through the
adjacent CGI endpoint.

## Try it

```sh
fossil clone http://HOST:6080/fossil/dig dig.fossil
mkdir dig-checkout
cd dig-checkout
fossil open ../dig.fossil
```
