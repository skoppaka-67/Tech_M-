// This file can be replaced during build by using the `fileReplacements` array.
// `ng build --prod` replaces `environment.ts` with `environment.prod.ts`.
// The list of file replacements can be found in `angular.json`.
// import * as conf from '../assets/js/config.json';

export const environment = {
  production: false,
  instance: 'natural',
  // apiUrl: 'http://13.234.96.84:5030/api/v1/'
  apiUrl: 'http://localhost:5008/api/v1/'

};


/*
      http://15.207.35.102:5000/api/v1/ - ip for aws crst
      instance - apiUrl
      local http://localhost:5000/api/v1/ http://localhost:5004/api/v1/
      tw - http://localhost:5010/api/v1/, http://localhost:5011/api/v1/ , https://lcaas.techm.name/backend-tm-prod/
      tw-im - https://lcaas.techm.name/backend-tm-im/ http://170.49.98.140:5000/api/v1/
      reverse proxy 
      mainframe - https://lcaas.techm.name/backend-mainframe/
      microfocus - https://lcaas.techm.name/backend-microfocus/
      as400 - https://lcaas.techm.name/backend-as400/
      natural - https://lcaas.techm.name/backend-natural/
      plsql - https://lcaas.techm.name/backend-plsql/
      vbnet/aps/uprr - https://lcaas.techm.name/backend-aps/
      vbnet_new - https://lcaas.techm.name/backend-vbnet/

      regular
      prod - http://13.234.96.84:5000/api/v1/
      as400 - http://13.234.96.84:5004/api/v1/
      microfocus - http://13.234.96.84:5005/api/v1/
      natural - http://13.234.96.84:5008/api/v1/
      plsql - http://13.234.96.84:5009/api/v1/
      uprr - http://13.234.96.84:5020/api/v1/
      vbnet_new - http://13.234.96.84:5020/api/v1/ 
*/

/*
    instance: tw, prod, as400, 
              natural, plsql, microfocus
    apiUrl: http://localhost:5000/api/v1/ , http://13.234.96.84:5000/api/v1/ , http://13.234.96.84:5004/api/v1/,
            http://13.234.96.84:5008/api/v1/, http://13.234.96.84:5009/api/v1/, http://13.234.96.84:5005/api/v1/

*/

/*
 * For easier debugging in development mode, you can import the following file
 * to ignore zone related error stack frames such as `zone.run`, `zoneDelegate.invokeTask`.
 *
 * This import should be commented out in production mode because it will have a negative impact
 * on performance if an error is thrown.
 */
// import 'zone.js/dist/zone-error';  // Included with Angular CLI.
