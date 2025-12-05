#!/usr/bin/env bash

if [[ $(basename "$PWD") != 'packages' ]]; then
  echo 'Expect to be run from within a packages directory?'>&2
  exit 1
elif [[ ! -d ocaml-variants/ocaml-variants.5.2.0+ox ]]; then
  echo 'Expect to be run in an OxCaml opam-repository?'>&2
  exit 1
fi

rm -rf oxcaml-*
last_guard=''
for entry in *; do
  if [[ -d $entry ]]; then
    [[ $entry != 'ocaml-variants' ]] || continue
    for package in "$entry/"*; do
      if [[ -e $package/opam ]]; then
        package="${package#"$entry"/}"
        case $package in
          *~preview.*)
            # Ignore JS 0.18 preview packages
            ;;
          *)
            if [[ -z $last_guard ]]; then
              mkdir -p oxcaml-patch-guards/oxcaml-patch-guards.ox
              cat > oxcaml-patch-guards/oxcaml-patch-guards.ox/opam <<EOF
opam-version: "2.0"
synopsis: "OxCaml patched upstream packages"
description: """
oxcaml-patch-guards and the associated oxcaml-* packages ensure that when a
non-Jane Street package in opam-repository has to be patched to work with OxCaml
that only those patched versions can be used in a switch with OxCaml."""
maintainer: "David Allsopp <david@tarides.com>"
authors: "David Allsopp"
license: "CC0-1.0+"
homepage: "https://oxcaml.org"
bug-reports: "https://github.com/oxcaml/opam-repository/issues"
depends: "oxcaml-$entry" {post} | "oxcaml-$entry-patches" {post}
EOF
            fi
            if [[ ! -e oxcaml-$entry/oxcaml-$entry.guard/opam ]]; then
              mkdir -p "oxcaml-$entry/oxcaml-$entry.guard"
              cat > "oxcaml-$entry/oxcaml-$entry.guard/opam" <<EOF
opam-version: "2.0"
synopsis: "OxCaml patched $entry (not installed)"
description: "OxCaml meta-package indicating this package is not installed"
maintainer: "David Allsopp <david@tarides.com>"
authors: "David Allsopp"
license: "CC0-1.0+"
homepage: "https://oxcaml.org"
bug-reports: "https://github.com/oxcaml/opam-repository/issues"
conflicts: [ "oxcaml-$entry-patches" "$entry" ]
EOF
              if [[ -n $last_guard ]]; then
                cat >> "oxcaml-$last_guard/oxcaml-$last_guard.guard/opam" <<EOF
depends: "oxcaml-$entry" {post} | "oxcaml-$entry-patches" {post}
EOF
              fi
              mkdir -p "oxcaml-$entry-patches/oxcaml-$entry-patches.enabled"
              cat > "oxcaml-$entry-patches/oxcaml-$entry-patches.enabled/opam" <<EOF
opam-version: "2.0"
synopsis: "OxCaml patched $entry"
description: "OxCaml meta-package indicating this library is installed"
maintainer: "David Allsopp <david@tarides.com>"
authors: "David Allsopp"
license: "CC0-1.0+"
homepage: "https://oxcaml.org"
bug-reports: "https://github.com/oxcaml/opam-repository/issues"
conflicts: "oxcaml-$entry"
depends: [
  "$entry" {build & (
  ${entry//?/ }      = "${package#"$entry".}"
EOF
              if [[ -n $last_guard ]]; then
                sed -i -e '/depends:/a\  ("oxcaml-'"$entry"'" {post} | "oxcaml-'"$entry"'-patches" {post})' "oxcaml-$last_guard-patches/oxcaml-$last_guard-patches.enabled/opam"
              fi
              last_guard="$entry"
            else
              cat >> "oxcaml-$entry-patches/oxcaml-$entry-patches.enabled/opam" <<EOF
  ${entry//?/ }    | = "${package#"$entry".}"
EOF
            fi;;
        esac
      fi
    done
  fi
done

for entry in oxcaml-*; do
  case $entry in
    oxcaml-*-patches)
      package="${entry#oxcaml-}"
      package="${package%-patches}"
      cat >> "$entry/"*"/opam" <<EOF
  ${package//?/ }    )}
]
EOF
      ;;
  esac
done
