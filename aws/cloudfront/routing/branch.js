function handler(event) {
  let request = event.request;
  let baseUrl = null;

  // determine base path for the environment
  if (['/feature', '/bugfix', '/hotfix', '/snapshot'].some(prefix => request.uri.startsWith(prefix))) {
    baseUrl = request.uri.split('/').slice(0, 3).join('/');
  } else if (['/dependabot'].some(prefix => request.uri.startsWith(prefix))) {
    baseUrl = request.uri.split('/').slice(0, 5).join('/');
  } else {
    baseUrl = "";
  }

  // check if we want a specific file
  if (!request.uri.replace(baseUrl, '').includes('.')) {
    request.uri = baseUrl + '/index.html';
  }

  return request;
}
