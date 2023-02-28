function addScript(url) {
  var script = document.createElement("script");
  script.setAttribute("type", "text/javascript");
  script.setAttribute("src", url);
  document.getElementsByTagName("head")[0].appendChild(script);
}

addScript("https://cdn.staticfile.org/jquery/1.10.2/jquery.min.js");
addScript("https://cdn.bootcss.com/node-uuid/1.4.8/uuid.min.js");
const courseIdentity =
  document.getElementById("CurCourseName").innerText +
  "-" +
  document.getElementById("SelectLessonIndex").innerText;
const user = document.getElementById("currentUserId");
const title = document.title;
const userId = user && parseInt(user.innerText);

let duration;

// function ajaxRequest({ userId, title, videoId, status }) {
//   $.ajax({
//     type: "post",
//     url: "https://api.keepwork.com/event-gateway/events/send",
//     data: JSON.stringify({
//       category: "behavior",
//       action: `videoProgress-${title}-${videoId}`,
//       data: {
//         traceId: uuid.v4(),
//         currentAt: Date.now(),
//         userId,
//         status,
//       },
//     }),
//     dataType: "json",
//     contentType: "application/json",
//     success: function (data) {
//       console.log("数据: \n" + JSON.stringify(data));
//     },
//   });
// }

function videoAllFinishRequest({ userId, courseIdentity, status }) {
  let action = "";
  let data = {
    traceId: uuid.v4(),
    currentAt: Date.now(),
    userId,
  }

  if (status == "start") {
    action = "crsp.course.watchVideo_inside.start"; // 1%
  } else if (status == "finish") {
    action = "crsp.course.watchVideo_inside.finish"; // 75%
  } else if (status == "videoStart") {
    action = "crsp.course.watchVideo_inside.videoStart"; // video start.
  } else if (status == "videoEnd") {
    action = "crsp.course.watchVideo_inside.videoEnd"; // video end.
    data.duration = duration;
  }

  $.ajax({
    type: "post",
    url: window.api + "/events/send",
    data: JSON.stringify({
      category: "behavior",
      action: `${action}-${courseIdentity}`,
      data: data,
    }),
    dataType: "json",
    contentType: "application/json",
    success: function (data) {
      console.log(
        `${courseIdentity} all video accomplished sent to remote: \n` +
          JSON.stringify(data)
      );
    },
  });
}

function getCustomizeVideoId(videoElem) {
  // bigfile customerId 三层父节点
  return (
    videoElem.parentNode &&
    videoElem.parentNode.parentNode &&
    videoElem.parentNode.parentNode.parentNode &&
    videoElem.parentNode.parentNode.parentNode.className === "player" &&
    videoElem.parentNode.parentNode.parentNode.id
  );
}

const map = {};
let videoSentFlag = false;
const videoIds = [];

function isAllVideoFinished() {
  for (const id of videoIds) {
    if (!map[id] || !map[id].finish) {
      return false;
    }
  }

  return true;
}

if (userId) {
  const elevideos = document.getElementsByTagName("video");

  for (const elevideo of elevideos) {
    let id = getCustomizeVideoId(elevideo) || elevideo.id;
    videoIds.push(id);
    let timer;

    elevideo.addEventListener("loadedmetadata", function () {
      //加载数据
      //视频的总长度
      duration = elevideo.duration;
      console.log(elevideo.duration);
      clearInterval(timer);
    });

    // elevideo.addEventListener("play", function () {
    //   //播放开始执行的函数
    //   console.log(id, "开始播放");
    //   map[id] = map[id] || {};
    //   if (!map[id].start) {
    //     // ajaxRequest({ userId, title, videoId: id, status: 0 });
    //     map[id].start = 1;
    //   }
    // });

    elevideo.addEventListener("playing", () => {
      //播放中
      console.log(id, "播放中");
      let process = parseFloat(elevideo.currentTime) / duration;

      timer = setInterval(() => {
        process = parseFloat(elevideo.currentTime) / duration;
        map[id] = map[id] || {};

        if (!map[id].videoStart && process > 0 && isElementInViewport(elevideo)) {
          console.log(id, "上报完成 视频开始");
          map[id].videoStart = 1;

          videoAllFinishRequest({ userId, courseIdentity, status: "videoStart" });
        }

        if (!map[id].started && process > 0.01 && isElementInViewport(elevideo)) {
          console.log(id, "上报完成0.01");
          map[id].started = 1;

          videoAllFinishRequest({ userId, courseIdentity, status: "start" });
        }

        if (!map[id].finish && process > 0.75 && isElementInViewport(elevideo)) {
          console.log(id, "上报完成0.75");
          map[id].finish = 1;

          videoAllFinishRequest({ userId, courseIdentity, status: "finish" });
        }

        if (!map[id].videoEnd && process > 0.99 && isElementInViewport(elevideo)) {
          console.log(id, "上报完成 完成");
          map[id].videoEnd = 1;

          if (courseIdentity && isAllVideoFinished() && !videoSentFlag) {
            videoAllFinishRequest({ userId, courseIdentity, status: "videoEnd" });
            videoSentFlag = true;
          }

          clearInterval(timer);
        }
      }, 1000);
    });

    // elevideo.addEventListener(
    //   "ended",
    //   function () {
    //     //结束
    //     if (!map[id].finish && isElementInViewport(elevideo)) {
    //       console.log(id, "上报完成");
    //       // ajaxRequest({ userId, title, videoId: id, status: 1 });
    //       map[id].finish = 1;

    //       if (courseIdentity && isAllVideoFinished() && !videoSentFlag) {
    //         const started = false;
    //         videoAllFinishRequest({ userId, courseIdentity, started });
    //         videoSentFlag = true;
    //       }

    //       clearInterval(timer);
    //     }
    //     clearInterval(timer);
    //     console.log(id, "播放结束");
    //   },
    //   false
    // );

    elevideo.addEventListener("pause", () => {
      //暂停开始执行的函数
      console.log("暂停播放");
      clearInterval(timer);
    });
  }
}

function isElementInViewport(el) {
  const rect = el.getBoundingClientRect();
  // return (
  //   rect.top >= 0 &&
  //   rect.left >= 0 &&
  //   rect.bottom <=
  //     (window.innerHeight ||
  //       document.documentElement.clientHeight) /*or $(window).height() */ &&
  //   rect.right <=
  //     (window.innerWidth ||
  //       document.documentElement.clientWidth) /*or $(window).width() */
  // );
  return (
    rect.top <= (window.innerHeight || document.documentElement.clientHeight) &&
    rect.bottom > 0
  );
}
