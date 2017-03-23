function sendFeedback(data) {
  $.ajax({
    type: "POST",
    url: "/feedback",
    dataType: "json",
    data: data,
    encode: true
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
  $("div.thankyou").css("display", "block");
  $("form").css("display", "none");
  $("p.instructions").css("display", "none");
  $("h2").css("display", "none");
}

$("form").submit(function(event) {

  var data = collectData();

  sendFeedback(data);

  event.preventDefault();

  renderThankyou();
});