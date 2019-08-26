# idlutils

A collection of IDL functions and routines used by a variety of SDSS software.

## Versioning

As of 6.0.0 we are using [bumpversion](https://github.com/peritus/bumpversion) to set the current version of idlutils. This replaces the previous system that used SVN variable substitution, which was deprecated with the migration to GitHub.

To install `bumpversion` run

```
pip install bumpversion
```

If, for example, the current version is `6.1.1` and you want to updte the minor version to `6.2.0` do `bumpversion minor` which will set the version to `6.2.0dev`. You can also modify the `major` or `patch` sections of the version. When you're ready to tag the product, run `bumpversion release` to remove the `dev` suffix. DO NOT MODIFY FILE VERSIONS DIRECTLY. For more information, read [this](https://sdss-python-template.readthedocs.io/en/latest/#bumpversion-section).
