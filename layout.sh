#!/usr/bin/env bash

export LC_ALL=C

if [[ $(basename "$PWD") != 'packages' ]]; then
  echo 'Expect to be run from within a packages directory?'>&2
  exit 1
elif [[ ! -d oxcaml-compiler ]]; then
  echo 'Expect to be run in an OxCaml opam-repository?'>&2
  exit 1
fi

mv oxcaml-compiler t-oxcaml-compiler
rm -rf oxcaml-*
mv t-oxcaml-compiler oxcaml-compiler

for entry in *; do
  if [[ -d $entry ]]; then
    case $entry in
      ocaml-variants|oxcaml-compiler|oxcaml)
        continue;;
    esac
    last=''
    for package in "$entry/"*; do
      if [[ -e $package/opam ]]; then
        package="${package#"$entry"/}"
        case $package in
          *~preview.*)
            # Ignore JS 0.18 preview packages
            ;;
          *)
            if [[ $last != $entry ]]; then
              case $entry in
                cmarkit|extlib|omd|yojson)
                  echo "5.2.0minus31:$entry";;
                *)
                  echo "5.2.0minus25:$entry";;
              esac
              last="$entry"
            fi
            ;;
        esac
      fi
    done
  fi
done > overrides

last_guard=''
last_since=''
declare -A VERSIONS
for entry in $(sort -t: -k1,1V -k2,2r overrides); do
  since="${entry%:*}"
  entry="${entry#*:}"
  VERSIONS[$since]="$entry"
  for package in "$entry/"*; do
    if [[ -e $package/opam ]]; then
      package="${package#"$entry"/}"
      case $package in
        *~preview.*)
          # Ignore JS 0.18 preview packages
          ;;
        *)
          if [[ ! -e oxcaml-$entry/oxcaml-$entry.guard/opam ]]; then
            mkdir -p "oxcaml-$entry/oxcaml-$entry.guard"
            case $entry in
              # These packages are only patched from a given version in OxCaml - the older versions don't (necessarily) require patches
              chrome-trace|dune-action-plugin|dune-build-info|dune-glob|dune-private-libs|dune-rpc-lwt|dune-site|xdg)
                constraint=' {>= "3.21.0"}';;
              *)
                constraint=''
            esac
            if [[ $since = '5.2.0minus25' ]]; then
              since_guard=''
            else
              since_guard=" \"oxcaml-compiler\" {< \"$since\"}"
            fi
            cat > "oxcaml-$entry/oxcaml-$entry.guard/opam" <<EOF
opam-version: "2.0"
synopsis: "OxCaml patched $entry (not installed)"
description: "OxCaml meta-package indicating this package is not installed"
maintainer: "David Allsopp <dallsopp@janestreet.com>"
authors: "David Allsopp"
license: "CC0-1.0+"
homepage: "https://oxcaml.org"
bug-reports: "https://github.com/oxcaml/opam-repository/issues"
conflicts: [ "oxcaml-$entry-patches" "$entry"$constraint$since_guard ]
messages: ["WARNING! An older version of OxCaml is being installed" {oxcaml:version = "archived"}]
depends: [
  "oxcaml" {post}
]
EOF
            if [[ -n $last_guard ]]; then
              sed -i -e '/depends:/a\  ("oxcaml-'"$last_guard"'" {post} | "oxcaml-'"$last_guard"'-patches" {post})' "oxcaml-$entry/oxcaml-$entry.guard/opam"
            fi
            mkdir -p "oxcaml-$entry-patches/oxcaml-$entry-patches.enabled"
            cat > "oxcaml-$entry-patches/oxcaml-$entry-patches.enabled/opam" <<EOF
opam-version: "2.0"
synopsis: "OxCaml patched $entry"
description: "OxCaml meta-package indicating this library is installed"
maintainer: "David Allsopp <dallsopp@janestreet.com>"
authors: "David Allsopp"
license: "CC0-1.0+"
homepage: "https://oxcaml.org"
bug-reports: "https://github.com/oxcaml/opam-repository/issues"
EOF
            if [[ $since = '5.2.0minus25' ]]; then
              cat >> "oxcaml-$entry-patches/oxcaml-$entry-patches.enabled/opam" <<EOF
conflicts: "oxcaml-$entry"
EOF
            else
              cat >> "oxcaml-$entry-patches/oxcaml-$entry-patches.enabled/opam" <<EOF
conflicts: ["oxcaml-$entry" "oxcaml-compiler" {< "$since"}]
EOF
            fi
            cat >> "oxcaml-$entry-patches/oxcaml-$entry-patches.enabled/opam" <<EOF
depends: [
  "oxcaml" {post}
  "$entry" {build & (
  ${entry//?/ }      = "${package#"$entry".}"
EOF
            if [[ -n $last_guard ]]; then
              sed -i -e '/depends:/a\  ("oxcaml-'"$last_guard"'" {post} | "oxcaml-'"$last_guard"'-patches" {post})' "oxcaml-$entry-patches/oxcaml-$entry-patches.enabled/opam"
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
  last_since="$since"
done

guard_clause=''
last_key=''
for k in $(printf '%s\n' "${!VERSIONS[@]}" | sort -r); do
  echo "$k = ${VERSIONS[$k]}"
  if [[ -z $guard_clause ]]; then
    oxcaml_version=''
  else
    oxcaml_version=' & "oxcaml-compiler" {post & < "'"$last_key"'"}'
    guard_clause="$guard_clause | "
  fi
  guard_clause="$guard_clause\"oxcaml-${VERSIONS[$k]}\" {post}$oxcaml_version | \"oxcaml-${VERSIONS[$k]}-patches\" {post}$oxcaml_version"
  last_key="$k"
done

mkdir -p oxcaml-patch-guards/oxcaml-patch-guards.ox
cat > oxcaml-patch-guards/oxcaml-patch-guards.ox/opam <<EOF
opam-version: "2.0"
synopsis: "OxCaml patched upstream packages"
description: """
oxcaml-patch-guards and the associated oxcaml-* packages ensure that when a
non-Jane Street package in opam-repository has to be patched to work with OxCaml
that only those patched versions can be used in a switch with OxCaml."""
maintainer: "David Allsopp <dallsopp@janestreet.com>"
authors: "David Allsopp"
license: "CC0-1.0+"
homepage: "https://oxcaml.org"
bug-reports: "https://github.com/oxcaml/opam-repository/issues"
depends: $guard_clause
EOF

rm -f overrides

for entry in oxcaml-*; do
  case $entry in
    oxcaml-*-patches)
      package="${entry#oxcaml-}"
      package="${package%-patches}"
      cat >> "$entry/"*"/opam" <<EOF
  ${package//?/ }    )}
]
messages: ["WARNING! An older version of OxCaml is being installed" {oxcaml:version = "archived"}]
EOF
      ;;
  esac
done
