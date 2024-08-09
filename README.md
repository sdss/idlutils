# idlutils

A collection of IDL functions and routines used by a variety of SDSS software.

## Should I be using the SVN version instead?

Until the end of SDSS-IV `idlutils` is maintained as a [SVN repository](https://trac.sdss.org/browser/repo/sdss/idlutils) and a GitHub repo (this one). SVN development happens as `v5_x`, while Git development uses the `6.x` series. The SVN `trunk` and the GitHub `master` branches will **not** synced until the end of SDSS-IV. `v5` tags are synced from SVN to GitHub every now and then. The `6.0.0` tag introduces breaking changes (see below).

So, what version should you be using? If you're developing SDSS-IV software (e.g., `mangadrp`, or the `apogee` pipeline), you probably want to keep using the `v5` branch and do your changes in SVN. If you're developing for SDSS-V you *should* be using the `6.x` tags and develop against the GitHub repository.

## External libraries

Version 6.x does not ship with the [Goddard](https://github.com/wlandsman/IDLAstro) and [Coyote](https://github.com/idl-coyote/coyote) libraries but `idlutils` still depends on them. You need to make sure that they are available in your `IDL_PATH`. Alternatively, you can use [sdss_install](https://github.com/sdss/sdss_install) to checkout a copy of `idlutils` while also installing Coyote and the Goddard libraries as modules.

## Versioning

Version 6.0.0 is the first one using `X.Y.Z.` instead of the previous `vX_Y_Z` syntax. If your product does idlutils version parsing you may need to update your code to handle both types of version string.

We use [bumpversion](https://github.com/peritus/bumpversion) to set the current version of idlutils. This replaces the previous system that used SVN variable substitution, which was deprecated with the migration to GitHub.

To install `bumpversion` run

```
pip install bumpversion
```

If, for example, the current version is `6.1.1` and you want to updte the minor version to `6.2.0` do `bumpversion minor` which will set the version to `6.2.0dev`. You can also modify the `major` or `patch` sections of the version. When you're ready to tag the product, run `bumpversion release` to remove the `dev` suffix. DO NOT MODIFY FILE VERSIONS DIRECTLY. For more information, read [this](https://sdss-python-template.readthedocs.io/en/latest/#bumpversion-section).

An alternative to `bumpversion`, do the following:

- Edit the `version` variable in the `bin/idlutils_version` file, with the new version number
- Add or update the `RELEASE_NOTES` with a new section for the version number, with release date
- Commit the changes
- In a terminal, run `git tag [version]`, where [version] is the new version number
- Run `git push origin [version]`
- Update the version number to next dev version and commit the change