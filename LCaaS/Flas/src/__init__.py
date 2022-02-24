from flask import *


app = Flask(__name__)

@app.route('/home/<name>')
def hW(name):
    return "Hello %s!" %name

def ohw():
    return "other way to say hello"
app.add_url_rule('/','ohw',ohw)


@app.route('/vald',methods = ['GET','POST'])
def vald():
    if request.method == 'POST':
        request.form['usrname']
        return  'validation Success'

    return  render_template('index.html')



if __name__ == '__main__':
    app.run(debug=True)