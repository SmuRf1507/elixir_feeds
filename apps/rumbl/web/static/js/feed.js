let Feed = {

  init(socket, element){
    if( !element ){ return }

    socket.connect()

    document.addEventListener("DOMContentLoaded", this.onReady(socket))


  },

  onReady(socket) {
    let feed_list = document.getElementsByClassName("feed-list")

    // Register each feed
    Array.prototype.forEach.call(feed_list, feed => {
      let feedID = feed.getAttribute("data-feedId")
      let feedChannel = socket.channel("feeds:" + feedID, {})

      /*#feedChannel.on("new_post", (resp) => {
        // when new post found
        #feedChannel.params.last_seen_id = resp.id
        this.renderNewPost(feed, resp)
      })*/

      feedChannel.on("new_post", post => {
        console.log("New Post:", post)
      })

      feedChannel.join()
        .receive("ok", resp => {
          console.log("join successfull", resp)
        })
        .receive("error", reason => console.log("join failed", reason))
    })
  },

  esc(str) {
    let div = document.createElement("div")
    div.appendChild(document.createTextNode(str))
    return div.innerHTML
  },

  renderNewPost(postContainer, {url, link, title, description, pubDate}){
    let template = document.createElement("li")

    template.innerHTML = `
    <a href="${this.esc(link)}" target="_blank">
      <b>${this.esc(title)}</b> - ${this.esc(pubDate)}
    </a><br />
    ${this.esc(description)}
    `
    // prepend new item to feed list
    postContainer.insertBefore(template, postContainer.childNodes[0])

    // Remove last item from list
    postContainer.removeChild(postContainer.childNodes[postContainer.childNodes.length - 1])

    // TODO Visually notify the User of the Update
  }
}
export default Feed
