---
layout: default
title: Painting Images with IPv6
date: 2023-04-14 13:07:43 -0500
tags: ipv6 python asyncio websocket PIL
_preview_description: Have you ever painted images with IPv6? I found out how in 30 minutes.
---

Despite how it sounds, this is not a joke. Well, maybe it is, but it's a fantastic demonstration of IPv6 addressing,
and you can join in on the fun right now too!

Some months ago, I found an interesting little site: [v6.sys42.net][place-v6]*.

> **Warning**: This site contains image curated by an unrestricted community: It is entirely out of my control what you
> will see on it, but _usually_, it's safe for work.

To give a short explanation of this site, it's similar to [/r/place][place-reddit], an online canvas where users can
place a single
pixel on a canvas every 5 minutes.

The difference between [/r/place][place-reddit] and [Place: IPv6][place-v6] is that the latter uses a human-accessible
user interface for
selecting colors and placing pixels, while the other uses IPv6 addresses.

Hold on - you might be thinking, _"Don't you mean a REST API? Or at least an HTTP webserver? Or even a TCP/UDP
socket?"_.

None of that, it's not just a normal server accessible by IPv6 exclusively - it's an IPv6 address range booked
specifically for the purpose of receiving R, G, B, X and Y arguments.

## How does it work?

To use the service, you send an ICMP packet (a `ping`) to a specific IPv6 address dictated by your arguments.

The arguments are encoded into the IPv6 address, and the service will receive and parse whatever you put into it.

> **Note**: The service has since been updated to use a different IPv6 address range, but the concept is the same.

Originally, the IPv6 address was {% ihighlight digdag %}2a06:a003:d040:SXXX:YYY:RR:GG:BB{% endihighlight %} where `XXX`
and `YYY` are the X and Y coordinates, and `RR`, `GG` and `BB` are the R, G and B values of the pixel. By substituting
you arguments into these positions, you can paint a pixel on the canvas. Lastly, the `S` represents the size of the
pixel.
Only `1` or `2` is accepted, representing a 1x1 or 2x2 pixel.

On top of this, the values are encoded in hexadecimal, so you can use the full range of 0-255 for each color without
worry.

As an example, painting the color {% ihighlight dart %}#008080{% endihighlight %} (teal) at the position `45, 445` would
be encoded as
{% ihighlight digdag %}2a06:a003:a040:102d:01bd:00:80:80{% endihighlight %}. To help you pick out the X and Y
coordinates, {% ihighlight java %}45{% endihighlight %} is {% ihighlight java %}0x2D{% endihighlight %} in hexadecimal,
and {% ihighlight java %}445{% endihighlight %}
is {% ihighlight java %}0x1BD{% endihighlight %}. The color is simply placing in the last 6 bytes of the address, no
hexadecimal conversion needed.

By now, the basic concept should be clear. You can paint a pixel by sending a `ping` to a specific IPv6 address with the
arguments encoded into it.

In Python, the encoding can be done like so:

```python
def get_ip(x: int, y: int, rgb: Tuple[int, int, int], large: bool = False):
    return f"2a06:a003:d040:{'2' if large else '1'}{x:03X}:{y:03X}:{rgb[0]:02X}:{rgb[1]:02X}:{rgb[2]:02X}"
```

> I've been interested in ways to format this dynamically with arbitrary base IPv6 addresses, but I haven't found
> a performant way of calculating it. It seems like it would require lots of bit shifting, precalculated constants,
> and a C extension to maximize performance. A future endeavour, perhaps.
> Additionally, the base IP does not change often (I have only observed it changing once).

## The Rest of Place: IPv6

IPv6 place includes a proper canvas to boot, and you can view it at [v6.sys42.net][place-v6], along with the basic
instructions on how to use it.

The way you view (and technically, receive information), is through a WebSocket connection. In the browser, you'll
receive updates that are combined into a Javascript-based canvas element.

On the initial page load, you'll receive a one-time message containing a PNG image of the current canvas. After that,
you'll receive partial updates whenever updates occur. These updates are also PNG images, but they are transparent
except for the pixels that have changed.

The WebSocket also contains information about PPS, or Pixels Per Second. This is the rate at which the canvas is
updated globally by all users. PPS messages are drawn onto a historical graph displayed below the canvas.

## 30 Minute Implementation

I had a lab due the day I decided to implement this, so I only had 30 minutes to spare. I decided to use Python, as it
offers a lot of flexibility and is my go-to language for anything quick.

I realized quite early on that any normal ping operations would be far too slow, and looked into batch pinging
implementations.

I found the [`multiping`][pypi-multiping] package first, and stuck with it. As the name implies, it specializes in
sending multiple pings at once, and is quite fast for Python. It also supports IPv6 without complaint.

The great part of this package is that it allows you to set timeouts - this is key in performance, as we don't care
about the response, only that the packet was sent. This allows us to send a large number of pings at once, and not
have to wait for a response.

Here was my first implementation:

```python
def upload_pixels(pixels: List[Pixel], chunk_size: int = None):
    """
    Given a list of pixels, upload them with the given chunk size.
    """
    ips = [get_ip(x, y, rgb) for x, y, rgb in pixels]
    return upload(ips, chunk_size)


def upload(ips: List[str], chunk_size: int = None):
    # Default to maximum chunk size
    if chunk_size is None: chunk_size = maximum_chunk

    chunked = list(chunkify(ips, min(maximum_chunk, chunk_size)))
    for i, chunk in enumerate(chunked, start=1):
        print(f'Chunk {i}/{len(chunked)}')
        multi_ping(chunk, timeout=0.2, retry=0)
```

`multiping` only supports sending a maximum of 10,000 pings at once, so I chunked the list of IPs into groups of 10,000
before letting `multiping` handle the rest.

Receiving data from the Websocket required a bit more guesswork, but the ultimate implementation is quite
straightforward:

```python
async def get_image(websocket):
    while True:
        data = await websocket.recv()
        if type(data) == bytes:
            return Image.open(io.BytesIO(data))
```

I decided to use [Pillow][pypi-pillow] for image manipulation, as it's a well-known and well-supported library. I
went with [`websockets`][pypi-websockets] for the WebSocket implementation.

Since the Websocket is used for both image updates and PPS data, a type check is required. PPS data is completely
ignored.

## The Final Implementation

While my first implementation was just fine for 30 minutes, and I could have left off there, I wanted to see if I could
do better. Initial usage demonstrated that any given pixel could fail to be placed - at high PPS, it seems some pixels
don't reach the server. Either the packets are dropped, they aren't ever sent, or the server simply doesn't process
them.

Whatever the case, a 'repainting' mechanism had to be implemented, and the Canvas had to be kept in memory.

I manage this with an async-based `PlaceClient` class that provides methods for receiving WebSocket updates, storing
the canvas image, identifying differences between the canvas and the local image, and sending pixels synchronously.

Here's what my final API looks like:

```python
client = await PlaceClient.connect(os.getenv(Environment.WEBSOCKET_ADDRESS))
# Set the current target to the image we want on the canvas
client.current_target = original_image
# Launch a background task to receive updates from the WebSocket and update our local 'canvas'
asyncio.create_task(client.receive())
# Paint the image with up to 5% error (difference tolerance)
await client.complete(0.05)
```

You can check out the repository at [github.com/Xevion/v6-place][github-v6-place].

[place-v6]: https://v6.sys42.net/

[place-reddit]: https://www.reddit.com/r/place/

[pypi-multiping]: https://pypi.org/project/multiping/

[pypi-pillow]: https://pypi.org/project/Pillow/

[pypi-websockets]: https://pypi.org/project/websockets/

[github-v6-place]: https://github.com/Xevion/v6-place