#!/usr/bin/env nu
# build separate images for each module in the repo

print $"(ansi green_bold)Gathering images"

let images = http get https://api.github.com/repos/nushell/nushell/releases | enumerate | each { |arrayEl|
    let release = $arrayEl.item

    let url = ($release.assets | where name ends-with "x86_64-unknown-linux-gnu.tar.gz").browser_download_url
    let version = $release.name

    let tags = (
        if ($env.GH_EVENT_NAME != "pull_request" and $env.GH_BRANCH == "main") {
            if ($arrayEl.index == 0) {
                ["latest", $version]
            } else {
                [$version]
            }
        } else if ($env.GH_EVENT_NAME != "pull_request") {
            [$"($version)-($env.GH_BRANCH)"]
        } else {
            [$"($version)-pr-($env.GH_PR_NUMBER)"]
        }
    )
    print $"(ansi cyan)Found version & generated tags:(ansi reset) ($tags | str join ' ')"

    {
        url: $url
        version: $version
        tags: $tags
    }
}

print $"(ansi green_bold)Starting image build(ansi reset)"

$images | each { |img|

    print $"(ansi cyan)Building image for version:(ansi reset) ($img.version)"
    (docker build .
        -f ./Containerfile
        ...($img.tags | each { |tag| ["-t", $"($env.REGISTRY)/nushell-image:($tag)"] } | flatten) # generate and spread list of tags
        --build-arg $"URL=($img.url)")

}

print $"(ansi cyan)Pushing images:(ansi reset)"
let digest = (
    docker push --all-tags $"($env.REGISTRY)/nushell-image"
        | split row "\n"  | last | split row " " | get 2 # parse push output to get digest for signing
)

print $"(ansi cyan)Signing image:(ansi reset) ($env.REGISTRY)/nushell-image@($digest)"
cosign sign -y --key env://COSIGN_PRIVATE_KEY $"($env.REGISTRY)/nushell-image@($digest)"

print $"(ansi green_bold)DONE!(ansi reset)"