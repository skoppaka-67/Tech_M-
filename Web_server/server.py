from flask import Flask,render_template,url_for,request,redirect
import csv


app = Flask(__name__)


@app.route('/')
def my_home(route=None):
    return render_template("index.html")


@app.route('/<string:page_name>')
def html_page(page_name):
    return render_template(page_name)

@app.route('/submit_form', methods=['POST', 'GET'])
def submit_form():
    if request.method == 'POST':
        data = request.form.to_dict()
        write_to_file(data)


        return redirect('/thankyou.html')
    else:
        return "somthing went wrong !"

    return "From submitted"

def write_to_file(data):
    with open('database.txt', 'a') as f:
        f.write("------------------------------------\n")
        f.write("|Email: " + str(data['email']) + '\n')
        f.write("|subject: " + str(data['subject']) + '\n')
        f.write("|message: " + str(data['message']) + '\n')
        f.write("-------------------------------------\n")

