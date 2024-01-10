import logging
import azure.functions as func

app = func.FunctionApp()


@app.function_name(name="HttpTrigger1")
@app.route(route="helloWorld", auth_level="anonymous")
def main(req):
    logging.info('Python HTTP trigger function processed a request.')
    user = req.params.get("user")
    return f"Hello {user} from Python!"
