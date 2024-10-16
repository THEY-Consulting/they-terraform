function handler(event) {
  let request = event.request;

  // check if we want a specific file
  if (!request.uri.includes('.')) {
    request.uri = '/index.html';
  }

  return request;
}
