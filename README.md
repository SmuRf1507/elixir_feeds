# Elixir Feeds

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Update config files
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Populate the database with `mix run priv/repo/seeds.exs`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# RSS Feeds

* Retrieve the latest items from a Feed
  ```
  RssGrabber.getXML(url, [limit: limit])  
  ```
* Or get a list of Feeds containing the latest items
  ```
  RssGrabber.getXMLbatch([url | tail], [limit: limit])
  ```
  
# Monitor Feeds

* Start the Feed Monitor, to continually check for new items on a Feed
    ```
    RssGrabber.start_feed_monitor(feed, opts)
    ```


# Front End

* Users can create Feeds, that are shared among all users and subscribe to a feed.
* Subscribed Feeds display the latest items, and update accordingly.
