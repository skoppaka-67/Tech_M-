import os
import logging
import json
#CONSTANTS



#Logger settings
logging.basicConfig(filename='app.log', filemode='a', format='[%(levelname)s]%(asctime)s:  %(message)s',level=logging.DEBUG)
logger = logging.getLogger(__name__)


def loadConfig():
    # Loading the configuration file
    with open('../config.json', 'r') as f:
        return json.load(f)

def validateProject(directory) -> bool:
    """
    Function check if the following conditions are satisfied:
    * Contains folders [COBOL,CopyBook,JCL,PROC]
    * Each sub folder only contains relevant files
    """
    if os.path.isdir(directory):
        logger.debug( 'Directory is valid, proceeding')
        contents = os.listdir(directory)
        found_folders=[]
        expected_folders = set(['COBOL','COPYBOOK','JCL','PROC'])

        for item in contents:
            if os.path.isdir(directory+'\\'+item):
                found_folders.append(item)

        found_folders = set(found_folders)

        if len(found_folders.difference(expected_folders).intersection(expected_folders)) is 0:
            logger.debug('The necessary folders exist, proceeding')
            return True

        else:
            logger.debug('Could not find the required folders in '+directory)
            return False

    else:
        logger.debug('Input: '+directory+' is not a valid directory')
        return False


