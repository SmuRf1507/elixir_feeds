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
        this.renderNewPost(feed, post)
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

  renderNewPost(postContainer, {link, title, description, pubDate}){
    //let template = document.createElement("div")
    let template = $("<li>").addClass("feed-entry list-group-item col-md-4").data("feedlink", link)
    let inner_html = `
    <a href="${this.esc(link)}" target="_blank" class="feed-title-link">
      <b>${this.esc(title)}</b> - ${this.esc(pubDate)}
    </a><br />
    ${this.esc(description)}
    `
    template.html(inner_html)
    // prepend new item to feed list
    $(postContainer).prepend(template)

    // Remove last item from list
    $(postContainer).find("li").last().remove()

    // TODO Visually notify the User of the Update
    $(postContainer).addClass("notify-active")
    let interval = setInterval(function(){
      $(postContainer).removeClass("notify-active")
      clearInterval(interval)
      return
    }, 6000)
    console.log("New Feed Update Successfull!")
  }
}
export default Feed
