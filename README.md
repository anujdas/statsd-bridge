# statsd-bridge

An HTTP-to-Datadog bridge for clients to send stats.

## Why?

Clients (whether web, iOS, Android, or other) frequently need instrumentation.
Datadog serves as a great place to stick these kinds of metrics (counts,
aggregates, stats), but it functions best with batched metrics; plus, we don't
want to provide API keys to (untrusted) clients. Furthermore, most
client-server applications already have some form of authentication, so it
doesn't make sense to reinvent the wheel and let clients auth directly with
Datadog.

Statsd-bridge is an extremely (EXTREMELY) simple HTTP/WS server that accepts
multiple kinds of Datadog metrics as well as tags and sends them up from the
server side via `dd-agent`. It provides no real logging or auth or anything
else; it's simply intended to be a passthrough run behind your API gateway so
that client metrics may be aggregated in one central location.

## Protocol

Statsd-bridge supports both bulk metrics via HTTP and streamed metrics via
Websockets. It offers one HTTP endpoint:

```
POST /stats
Content-Type: application/json
Body:
  {
    count: [
      ['stat_name', amount],
      ...
    ],
    gauge: [
      ['stat_name', value],
      ...
    ],
    timing: [
      ['stat_name', milliseconds],
      ...
    ],
    tags: [
        'tag:value',
      ...
    ]
  }
```

The only response is a `202 Accepted` if the request was well-formatted.
Partial delivery is possible if not all metrics were processable. All fields
are optional. `tags` should be provided in the Datadog standard format
`tag_name:tag_value`; usual caveats regarding tag cardinality apply.

A request upgrading to Websockets should instead send metrics line-by-line in
the format

```
operation stat_name value tag1 tag2 ...
```

Operation should be one of (`count`, `gauge`, `timing`). `tags` are optional.
All fields should be space separated (this was chosen because spaces are not
valid in stats, values, or tags). If successful, a '1' will be written back to
the client; if unsuccessful, nothing will be sent.

## Running

Statsd-bridge is built on `iodine`, a high-performance webserver for Ruby.
Refer to that project for additional options, but in general the most useful
commands are:

```bash
# Set up dependencies
> bundle install

# Run silently with auto-detected best settings on port 3000
> bundle exec iodine

# Run verbosely on port 9090 with 1 process
> bundle exec iodine -p 9090 -w 1 -v

# Set dd-agent host, port, and metrics namespace
> STATSD_HOST=localhost STATSD_PORT=18125 STATSD_NAME=my_stats bundle exec iodine
```

## Links

  - [Iodine](https://github.com/boazsegev/iodine) - "a fast concurrent web server for real-time Ruby applications"
  - [Datadog](https://www.datadoghq.com/) - "modern monitoring & analytics"
