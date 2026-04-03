window.addEventListener("pageswap", (e) => {
  if (e.viewTransition && e.activation.navigationType === "traverse") {
    e.viewTransition.skipTransition();
  }
});
