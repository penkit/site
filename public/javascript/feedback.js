function sendFeedback(data) {
  $.ajax({
    type: "POST",
    url: "/feedback",
    dataType: "json",
    data: data,
    encode: true,
    success: function(data) {
      if (data["success"] == "true") {
        renderThankyou();
      } else {
        $("html, body").animate({ scrollTop: 0 }, "slow");
        displayAlert("Something went wrong.");
        $("i#loading").css("display", "none");
        $("input#submit").css("display", "inline-block");
        $("input#submit").attr("value", "Submit");
      }
    }
  });
}

function collectData() {
  var data = {}

  $("form").find("input").each(function(){
    if (this.value == "") {
      this.value = "(none)"
    }

    data[this.name] = this.value;
  });

  $("form").find("textarea").each(function(){
    if (this.value == "") {
      this.value = "(none)"
    }

    data[this.name] = this.value;
  });
  
  return data;
}

function renderThankyou() {
  clearAlert();
  $("html, body").animate({ scrollTop: 0 }, "slow");
  $("i#loading").css("display", "none");
  $("div.thankyou").css("display", "block");
  $("form").css("display", "none");
  $("p.instructions").css("display", "none");
  $("h2").css("display", "none");
}

function displayAlert(msg) {
  $("#alert").css("display", "block");
  $("#alert").html(msg);
}

function clearAlert() {
  $("#alert").empty();
  $("#alert").css("display", "none");
}

$("form").submit(function(event) {

  var data = collectData();

  sendFeedback(data);

  event.preventDefault();

  $("i#loading").css("display", "block");
  $("input#submit").css("display", "none");
});