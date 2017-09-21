defmodule RssGrabber.UrlError do
  defexception message: "** (RssGrabber.URLInvalidError) Unable to reach provided URL, make sure it's spelled correctly."
end
