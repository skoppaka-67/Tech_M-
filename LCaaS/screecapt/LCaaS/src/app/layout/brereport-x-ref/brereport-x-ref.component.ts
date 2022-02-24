import { Component, OnInit, ViewChild } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import * as domtoimage from 'dom-to-image';
declare var flowchart: any;

@Component({
    selector: 'app-brereport-xref',
    templateUrl: './brereport-x-ref.component.html',
    styleUrls: ['./brereport-x-ref.component.scss'],
    animations: [routerTransition()]
})

export class BreReportXRefComponent implements OnInit {

  constructor(
    public dataservice: DataService,
    public excelService: ExcelService,
    config: NgbModalConfig,
    private modalService: NgbModal
) {
    config.backdrop = 'static';
    config.keyboard = false;

}
  title = 'BRE Report';
  componentList: any[] = [];
   selectedComponent = '';
   flowName = '';
   content: string;
   content4: string;
   dataSets: any = null;
    excelDataSet: any[] = [];
    dtOptions: DataTables.Settings = {};
    @ViewChild(DataTableDirective)
    dtElement: DataTableDirective;
    element: HTMLElement;
    dtTrigger: Subject<any> = new Subject();
    showLoader = false;
    compName = '';
    codeString = '';
    errormessage = '';
    applicationTypeList: any[] = [];
    programNameList: any[] = [];
    selectedApplication = '';
    searchFilter = '';
    ngOnInit(): void {
      window.scrollTo(0, 0);
      setTimeout(() => {
      const tableCont = document.querySelector('#table-cont');
        function scrollHandle (e) {
            const scrollTop = this.scrollTop;
            this.querySelector('thead').style.transform = 'translateY(' + scrollTop + 'px)';
        }
        tableCont.addEventListener('scroll', scrollHandle);
      }, 1100);
      this.dtOptions =  {
        pagingType: 'full_numbers' ,
        paging : true,
        search : true,
     //   ordering : true,
        order: [],
        autoWidth : false,
            columnDefs: [
                { 'width': '10%', 'targets': 0 },
                { 'width': '10%', 'targets': 1 },
                { 'width': '30%', 'targets': 2 },
                { 'width': '30%', 'targets': 3 },
                { 'width': '10%', 'targets': 4 },
                { 'width': '20%', 'targets': 5 },
                { 'width': '10%', 'targets': 6 }
              ],
       // searching :true,
        scrollY : '350',
        scrollX : true
      };
      (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
      // this.getComponentList();
      this.applicationList();
     this.getBREReportDetailsNew('', true, '');
    }
    applicationList() {
      this.dataservice.getApplicationList().subscribe(res => {
        this.applicationTypeList = res.application_list;
        console.clear();
    });
    }
    getComponentList() {
      this.dataservice.getComponentList().subscribe(res => {
          this.componentList = res.program_list;
      });
    }
    applicationTypeOnchange(event: any) {
      this.getProgramNameList(event.target.value);
      this.selectedApplication = event.target.value;
    }
    getProgramNameList(selectedApplication) {
      this.dataservice.getProgramNameList(selectedApplication).subscribe(res => {
        this.programNameList = res.component_list;
    });
    }
    programNameOnchange(event: any) {
      if (event.target.value === '') {
        this.selectedComponent = '';
        (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
    } else {
        this.selectedComponent = event.target.value;
        (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
    }
    }
    onChange(component: string) {
      if (component === '') {
          this.selectedComponent = '';
          (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'hidden';
      } else {
          this.selectedComponent = component;
          console.log('onchange');
          (document.getElementById('codeBtn') as HTMLInputElement).style.visibility = 'visible';
      }
    }
    onSubmit() {
      this.showLoader = true;
      this.getBREReportDetailsNew(this.selectedComponent, false, '');
      this.showLoader = false;
      
    //   setTimeout(() => {
    //     $( $('#dataTbl').DataTable().column(1).nodes()).addClass('highlight');
    //     $( $('#dataTbl').DataTable().column(3).nodes()).addClass('highlight');
    // }, 1100);
    setTimeout(() => {
      $('#dataTbl td:nth-child(2)').each(function(i) {
          $(this).addClass('highlight');
      });
      $('#dataTbl td:nth-child(4)').each(function(i) {
          $(this).addClass('highlight');
      });
  }, 1100);   

    }
    getBREReportDetailsNew(selectedComponent, intializeTable: boolean, searchFilter) {
      if (intializeTable) {
      this.dataservice.getBREReportDetailsNewXRef(selectedComponent, searchFilter).subscribe(res => {
        for (let i = 0; i < res.data.length; i++) {
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/<br>/g, '\n');
          res.data[i]['rule_description'] = res.data[i]['rule_description'].toString().replace(/<br>/g, '\n');
        }
          this.dataSets = res;
          var dataJSON = {};
            var dataList = [];
            var headerList = res.headers;
            for(var i=0;i<res.data.length;i++){
                for(var j=0;j<headerList.length;j++){
                    dataJSON[headerList[j]] = res.data[i][headerList[j]];
                }
                dataList.push(dataJSON);
                dataJSON= {};
            }
            // console.log(dataList);
          this.excelDataSet = dataList;
         // this.dtTrigger.next();
      });
    } else {
      this.dataservice.getBREReportDetailsNew(selectedComponent).subscribe(res => {
        for (let i = 0; i < res.data.length; i++) {
          res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/<br>/g, '\n');
          res.data[i]['rule_description'] = res.data[i]['rule_description'].toString().replace(/<br>/g, '\n');
        }
          this.dataSets = res;
          var dataJSON = {};
            var dataList = [];
            var headerList = res.headers;
            for(var i=0;i<res.data.length;i++){
                for(var j=0;j<headerList.length;j++){
                    dataJSON[headerList[j]] = res.data[i][headerList[j]];
                }
                dataList.push(dataJSON);
                dataJSON= {};
            }
            // console.log(dataList);
          this.excelDataSet = dataList;
        // this.rerender();
      });
    }
    
    }
    // rerender(): void {
    //   this.dtElement.dtInstance.then((dtInstance: DataTables.Api) => {
    //     dtInstance.destroy();
    //     this.dtTrigger.next();
    //   });
    // }
    filterTable() {
      this.searchFilter = (document.getElementById('searchFilter') as HTMLInputElement).value;
      if (this.searchFilter.length > 2) {
          (document.getElementById('searchButton') as HTMLInputElement).disabled = true;
          (document.getElementById('clearButton') as HTMLInputElement).disabled = true;
          this.showLoader = true;
          this.dataservice.getBREReportDetailsNewXRef(this.selectedComponent, this.searchFilter).subscribe(res => {
            for (let i = 0; i < res.data.length; i++) {
              res.data[i]['source_statements'] = res.data[i]['source_statements'].toString().replace(/<br>/g, '\n');
              res.data[i]['rule_description'] = res.data[i]['rule_description'].toString().replace(/<br>/g, '\n');
            }  
            this.dataSets = res;
              (document.getElementById('totalrecords') as HTMLInputElement).innerHTML = 'Total no of records: ' + res.data.length;
              
              var dataJSON = {};
            var dataList = [];
            var headerList = res.headers;
            for(var i=0;i<res.data.length;i++){
                for(var j=0;j<headerList.length;j++){
                    dataJSON[headerList[j]] = res.data[i][headerList[j]];
                }
                dataList.push(dataJSON);
                dataJSON= {};
            }
            // console.log(dataList);
          this.excelDataSet = dataList;
              (document.getElementById('searchButton') as HTMLInputElement).disabled = false;
              (document.getElementById('clearButton') as HTMLInputElement).disabled = false;
              this.showLoader = false;
              setTimeout(() => {
                $('#dataTbl td:nth-child(2)').each(function(i) {
                    $(this).addClass('highlight');
                });
                $('#dataTbl td:nth-child(4)').each(function(i) {
                    $(this).addClass('highlight');
                });
            }, 1100);  
          });
      } else {
          alert('Enter atleast 3 characters');
          (document.getElementById('searchFilter') as HTMLInputElement).focus();
          return false;
      }
  }
  clearFilter() {
      (document.getElementById('searchFilter') as HTMLInputElement).value = '';
      this.getBREReportDetailsNew(this.selectedComponent, false, '');
      setTimeout(() => {
        $('#dataTbl td:nth-child(2)').each(function(i) {
            $(this).addClass('highlight');
        });
        $('#dataTbl td:nth-child(4)').each(function(i) {
            $(this).addClass('highlight');
        });
    }, 1100);  
      return false;
  }
    exportAsXLSX(): void {
    this.excelService.exportAsExcelFile(this.excelDataSet, (document.getElementById('pgmName') as HTMLInputElement).value);
    }
    open(content) {
        this.modalService.open(content);
        (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
        (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
        (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
        (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;
        this.compName = this.selectedComponent;
        console.log(this.compName);
        (document.getElementById('compName') as HTMLInputElement).innerText = this.compName;
        this.dataservice.getComponentCode(this.compName, 'COBOL').subscribe(res => {
          this.codeString = res.codeString;
          /*this.codeString = this.codeString
          .replace(/\"/g, '"').replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
          .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
          .replace(/  /g, '&nbsp;&nbsp;')
          .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');*/
          try{
            this.codeString = this.codeString.replace(/\"/g, '"')
          } catch{
            console.log('err 1');
          }
          try{
            this.codeString = this.codeString
            .replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          } catch {
            console.log('err 2');
          }
          try{
            this.codeString = this.codeString
          .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          } catch {
            console.log('err 3');
          }
          try{
            this.codeString = this.codeString
          .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          } catch {
            console.log('err 4');
          }
          try{
            this.codeString = this.codeString
          .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
          } catch {
            console.log('err 5');
          }
          try{
            this.codeString = this.codeString
          .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
          } catch {
            console.log('err 6');
          }
          try{
            this.codeString = this.codeString
          .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
          } catch {
            console.log('err 7');
          }
          try{
            this.codeString = this.codeString
          .replace(/  /g, '&nbsp;&nbsp;')
          } catch {
            console.log('err 8');
          }
          try{
            this.codeString = this.codeString
          .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;')
          } catch {
            console.log('err 9');
          }
            document.getElementById('canvasCode').innerHTML = this.codeString;
            (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';
        }, error => {
          this.errormessage = 'Code not available for current component';
          (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
  });
  }
  showFlowChart(flow, compName, header, compTypeObj){
    if(header === 'PARA_NAME' || header === 'para_name'){
      this.modalService.open(flow, compName);
      if(compName.indexOf('.')>0){
        this.flowName = compName.split('.')[0];
      }
      else {
        this.flowName = compName;
      }
    (document.getElementById('flowChartBtn') as HTMLInputElement).disabled = true;
    // console.log(flow, compName, header);

  this.dataservice.getFlowChartContent(this.selectedComponent, this.flowName).subscribe(res => {
    // console.log(this.selectedComponent, this.flowName);
    if (res.status === 'available') {
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'hidden';
      this.content = res.option;
      this.content = this.content.toString().replace(/<br>/g, '\n');
      const chart = flowchart.parse(this.content);
      chart.drawSVG('canvas', {
          'x': 15,
          'y': 10,
          'line-width': 1,
          'line-length': 1,
          'text-margin': 15,
          'font-size': 14,
          'font': 'normal',
          'font-family': 'Helvetica',
          'font-weight': 'normal',
          'font-color': 'black',
          'line-color': 'black',
          'element-color': 'black',
          'fill': 'white',
          'yes-text': 'yes',
         'no-text': 'no',
          'arrow-end': 'block',
          'symbols': {
            'start': {
              'font-color': 'black',
              'element-color': 'black',
              'fill': 'white'
            },
            'end': {
              'class': 'end-element'
            }
          },
          'flowstate': {
            'past': {
                'fill': '#99cc00',
                    'font-size': 12
            },
                'current': {
                'fill': 'white',
                    'font-color': 'black' // ,
                    // 'font-weight': 'bold'
            },
                'future': {
                'fill': '#9933ff'
          },
                'request': {
                'fill': 'ffffff'
            },
                'invalid': {
                'fill': '#444444'
            },
                'approved': {
                'fill': '#00ccff',
                    'font-size': 12 // ,
                    // 'yes-text': 'APPROVED',
                    // 'no-text': 'n/a'
            },
            'io': {
            'fill': '#cccccc',
                'font-size': 12
        },
                'rejected': {
                'fill': '#ff471a',
                    'font-size': 12 // ,
                    // 'yes-text': 'n/a',
                    // 'no-text': 'REJECTED'
            }
        }
      });
      // var svg = document.getElementsByTagName('svg')[0];
      // svg.setAttribute('width', '1000px');
    } else if (res.status === 'unavailable') {
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'visible';
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.color = 'red';
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).innerHTML = 'Data is not available for selected para!!';
    }
  });
      // setTimeout(() => {
      //   $( $('#dataTbl').DataTable().column(1).nodes()).addClass('highlight');
      //   $( $('#dataTbl').DataTable().column(3).nodes()).addClass('highlight');
      // }, 1100);
      setTimeout(() => {
        $('#dataTbl td:nth-child(2)').each(function(i) {
            $(this).addClass('highlight');
        });
        $('#dataTbl td:nth-child(4)').each(function(i) {
            $(this).addClass('highlight');
        });
    }, 1100);
    }
  }
  openEditablePopup(content, compName, header, compTypeObj){
    if(header === 'RULE_DESCRIPTION' || header === 'rule_description'){
      this.modalService.open(content);
      // $("#pgm_name").blur();
      // (document.getElementById('editTableContentBody') as HTMLInputElement).innerHTML = 
      // compTypeObj['pgm_name'] + ',' + compTypeObj['para_name'] + ',' + compTypeObj['source_statements']
      // + ',' + compTypeObj['rule_description'] + ',' + compTypeObj['Rule'] + ',' + compTypeObj['rule_relation'];

      var fragment_id = compTypeObj['fragment_id'];
      var pgm_name = compTypeObj['pgm_name'];
      var para_name = compTypeObj['para_name'];
      var source_statements = compTypeObj['source_statements'];
      var rule_description = compTypeObj['rule_description'];
      var rule_category = compTypeObj['rule_category'];
      var Rule = compTypeObj['Rule'];
      var rule_relation = compTypeObj['rule_relation'];

      (document.getElementById('fragment_id') as HTMLInputElement).value = fragment_id;
      (document.getElementById('pgm_name') as HTMLInputElement).value = pgm_name;
      (document.getElementById('para_name') as HTMLInputElement).value = para_name;
      (document.getElementById('source_statements') as HTMLInputElement).value = source_statements;
      (document.getElementById('rule_description') as HTMLInputElement).value = rule_description;
      (document.getElementById('rule_category') as HTMLInputElement).value = rule_category;
      (document.getElementById('Rule') as HTMLInputElement).value = Rule;
      (document.getElementById('rule_relation') as HTMLInputElement).value = rule_relation;
    }
  }
  updateRule(){
    var fragment_id = (document.getElementById('fragment_id') as HTMLInputElement).value;
    var pgm_name = (document.getElementById('pgm_name') as HTMLInputElement).value;
    var para_name = (document.getElementById('para_name') as HTMLInputElement).value;
    var source_statements = (document.getElementById('source_statements') as HTMLInputElement).value;
    var rule_description = (document.getElementById('rule_description') as HTMLInputElement).value;

    rule_description = rule_description.replace(/\n/g, '\n').replace(/\s/g, ' ');
    console.log(rule_description);

    var rule_category = (document.getElementById('rule_category') as HTMLInputElement).value;
    var Rule = (document.getElementById('Rule') as HTMLInputElement).value;
    var rule_relation = (document.getElementById('rule_relation') as HTMLInputElement).value;
    this.dataservice.updateBREReportTrial(fragment_id, rule_description, rule_category).subscribe(res => {
          // console.log(res);
          if(res.yo === 'yo'){
            (document.getElementById('uploadupdateMsg') as HTMLInputElement).style.color = 'green';
            (document.getElementById('uploadupdateMsg') as HTMLInputElement).innerHTML = 'Successfully updated record';
          } else {
            (document.getElementById('uploadupdateMsg') as HTMLInputElement).style.color = 'red';
            (document.getElementById('uploadupdateMsg') as HTMLInputElement).innerHTML = 'Record could not be updated';
          }
    });
  }
  updateTable() {
    this.getBREReportDetailsNew(this.selectedComponent, false, '');
  //   setTimeout(() => {
  //     $( $('#dataTbl').DataTable().column(1).nodes()).addClass('highlight');
  //     $( $('#dataTbl').DataTable().column(3).nodes()).addClass('highlight');
  // }, 1100);
  setTimeout(() => {
    $('#dataTbl td:nth-child(2)').each(function(i) {
        $(this).addClass('highlight');
    });
    $('#dataTbl td:nth-child(4)').each(function(i) {
        $(this).addClass('highlight');
    });
}, 1100);
  }

  showExpandedCode(){
    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('canvasCode') as HTMLInputElement).style.height = '0%';
    (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'visible';
    (document.getElementById('expandedCode') as HTMLInputElement).style.height = '100%';

    (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = true;
    (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = false;

    this.dataservice.getExpandedComponentCode(this.compName, 'COBOL').subscribe(res => {
      this.codeString = res.codeString;
      //this.codeString = this.codeString
      /*.replace(/\"/g, '"')
      .replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
      .replace(/  /g, '&nbsp;&nbsp;')
      .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');*/
      try{
        this.codeString = this.codeString.replace(/\"/g, '"')
      } catch{
        console.log('err 1');
      }
      try{
        this.codeString = this.codeString
        .replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 2');
      }
      try{
        this.codeString = this.codeString
      .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 3');
      }
      try{
        this.codeString = this.codeString
      .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 4');
      }
      try{
        this.codeString = this.codeString
      .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 5');
      }
      try{
        this.codeString = this.codeString
      .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 6');
      }
      try{
        this.codeString = this.codeString
      .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 7');
      }
      try{
        this.codeString = this.codeString
      .replace(/  /g, '&nbsp;&nbsp;')
      } catch {
        console.log('err 8');
      }
      try{
        this.codeString = this.codeString
      .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;')
      } catch {
        console.log('err 9');
      }
        document.getElementById('expandedCode').innerHTML = this.codeString;
        (document.getElementById('expandedCode') as HTMLInputElement).style.fontFamily = 'Courier';
    }, error => {
      this.errormessage = 'Code not available for current component';
      (document.getElementById('expandedCode') as HTMLInputElement).innerHTML = this.errormessage;
  });
  }
  showCode(){
    (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'visible';
    (document.getElementById('canvasCode') as HTMLInputElement).style.height = '100%';
    (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
    (document.getElementById('showCodeBtn') as HTMLInputElement).disabled = true;

  }
  domtoImage() {
    if((document.getElementById('canvasTwo') as HTMLInputElement).style.visibility === 'visible'){
      const node = document.getElementById('canvasTwo');
      domtoimage.toPng(node).then(function (dataUrl) {
         const img = new Image();
          img.src = dataUrl;
          const link = document.createElement('a');
          link.setAttribute('href', img.src);
          link.setAttribute('download', (document.getElementById('flowName') as HTMLInputElement).innerText + '_TranslatedFlowChart');
          link.click();
  
      }).catch(function (error) {
          console.error('oops, something went wrong!', error);
      });
    } else if((document.getElementById('canvas') as HTMLInputElement).style.visibility = 'visible'){
      const node = document.getElementById('canvas');
      domtoimage.toPng(node).then(function (dataUrl) {
       const img = new Image();
        img.src = dataUrl;
        const link = document.createElement('a');
        link.setAttribute('href', img.src);
        link.setAttribute('download', (document.getElementById('flowName') as HTMLInputElement).innerText + '_FlowChart');
        link.click();

    }).catch(function (error) {
        console.error('oops, something went wrong!', error);
    });
    }
  }
  showFlowChartOne() {

    (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'visible';

    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('canvasTwo') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('canvas') as HTMLInputElement).style.visibility = 'visible';

    (document.getElementById('dwnBtn') as HTMLInputElement).style.visibility = 'visible'; // changed for now

    (document.getElementById('flowChartBtn') as HTMLInputElement).disabled = true;
    (document.getElementById('flowChartBtn2') as HTMLInputElement).disabled = false;
    (document.getElementById('paraCodeBtn') as HTMLInputElement).disabled = false;

    (document.getElementById('canvas') as HTMLInputElement).style.height = '100%';
    (document.getElementById('canvasTwo') as HTMLInputElement).style.height = '0%';
    (document.getElementById('canvasCode') as HTMLInputElement).style.height = '0%';

    setTimeout(() => {
      const elmnt = document.getElementById('canvas');
      try {
        elmnt.scrollIntoView();
      } catch (e) {
        console.log(e + 'No flowchart found');
      }
    }, 1100);

  }
  showFlowChartTwo(){
    this.dataservice.getFlowChartTwoContent(this.selectedComponent, this.flowName).subscribe(res => {
      if (res.status === 'available') {
        (document.getElementById('canvasTwo') as HTMLInputElement).innerHTML = '';
        (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'hidden';
        this.content4 = res.option;
        this.content4 = this.content4.toString().replace(/<br>/g, '\n');
        // console.log(this.content4);
        const chart1 = flowchart.parse(this.content4);
        chart1.drawSVG('canvasTwo', {
            'x': 15,
            'y': 10,
            'line-width': 1,
            'line-length': 1,
            'text-margin': 15,
            'font-size': 14,
            'font': 'normal',
            'font-family': 'Helvetica',
            'font-weight': 'normal',
            'font-color': 'black',
            'line-color': 'black',
            'element-color': 'black',
            'fill': 'white',
            'yes-text': 'yes',
           'no-text': 'no',
            'arrow-end': 'block',
            'symbols': {
              'start': {
                'font-color': 'black',
                'element-color': 'black',
                'fill': 'white'
              },
              'end': {
                'class': 'end-element'
              }
            },
            'flowstate': {
              'past': {
                  'fill': '#99cc00',
                      'font-size': 12
              },
                  'current': {
                  'fill': 'white',
                      'font-color': 'black' // ,
                      // 'font-weight': 'bold'
              },
                  'future': {
                  'fill': '#9933ff'
            },
                  'request': {
                  'fill': 'ffffff'
              },
                  'invalid': {
                  'fill': '#444444'
              },
                  'approved': {
                  'fill': '#00ccff',
                      'font-size': 12 // ,
                      // 'yes-text': 'APPROVED',
                      // 'no-text': 'n/a'
              },
              'io': {
              'fill': '#cccccc',
                  'font-size': 12
          },
                  'rejected': {
                  'fill': '#ff471a',
                      'font-size': 12 // ,
                      // 'yes-text': 'n/a',
                      // 'no-text': 'REJECTED'
              }
        }
        });
        // var svg = document.getElementsByTagName('svg')[1];
        // svg.setAttribute('width', '1000px');
    } else if (res.status === 'unavailable') {
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'visible';
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.color = 'red';
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).innerHTML = 'Data is not available for selected para!!';
    }
    });
    (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'visible';

    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('canvas') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('canvasTwo') as HTMLInputElement).style.visibility = 'visible';

    (document.getElementById('dwnBtn') as HTMLInputElement).style.visibility = 'visible';

    (document.getElementById('flowChartBtn2') as HTMLInputElement).disabled = true;
    (document.getElementById('flowChartBtn') as HTMLInputElement).disabled = false;
    (document.getElementById('paraCodeBtn') as HTMLInputElement).disabled = false;

    (document.getElementById('canvasTwo') as HTMLInputElement).style.height = '100%';
    (document.getElementById('canvas') as HTMLInputElement).style.height = '0%';
    (document.getElementById('canvasCode') as HTMLInputElement).style.height = '0%';
    setTimeout(() => {
      const elmnt = document.getElementById('canvasTwo');
      try {
        elmnt.scrollIntoView();
      } catch (e) {
        console.log(e + 'No flowchart found');
      }
    }, 1100);
  }
  showParaCode() {
    (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'hidden';

    (document.getElementById('dwnBtn') as HTMLInputElement).style.visibility = 'hidden';
    
    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'visible';
    (document.getElementById('canvas') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('canvasTwo') as HTMLInputElement).style.visibility = 'hidden';

    (document.getElementById('canvas') as HTMLInputElement).style.height = '0%';
    (document.getElementById('canvasTwo') as HTMLInputElement).style.height = '0%';
    (document.getElementById('canvasCode') as HTMLInputElement).style.height = '100%';

    (document.getElementById('flowChartBtn') as HTMLInputElement).disabled = false;
    (document.getElementById('flowChartBtn2') as HTMLInputElement).disabled = false;
    (document.getElementById('paraCodeBtn') as HTMLInputElement).disabled = true;

    this.dataservice.getComponentCode(this.selectedComponent, 'COBOL').subscribe(res => {
      this.codeString = res.codeString;

      this.codeString = this.codeString
      .replace(/\"/g, '"')
      .replace(/        /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/       /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/      /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/     /g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/    /g, '&nbsp;&nbsp;&nbsp;&nbsp;')
      .replace(/   /g, '&nbsp;&nbsp;&nbsp;')
      .replace(/  /g, '&nbsp;&nbsp;')
      .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;');

      if (this.codeString.indexOf(this.flowName.toString() + '.') > 0) {
        const replaceStr = '<span id="canvasScroll">' +
          this.flowName.toString() + '.' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + '.', replaceStr);
      }
      if (this.codeString.indexOf(this.flowName.toString() + ' section.') > 0) {
        const replaceStr1 = '<span id="canvasScroll">' +
          this.flowName.toString() + ' section.' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + ' section.', replaceStr1);
      }
      if (this.codeString.indexOf(this.flowName.toString() + ' Section.') > 0) {
        const replaceStr2 = '<span id="canvasScroll">' +
          this.flowName.toString() + ' Section.' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + ' Section.', replaceStr2);
      }
      if (this.codeString.indexOf(this.flowName.toString() + ' SECTION.') > 0) {
        const replaceStr3 = '<span id="canvasScroll">' +
          this.flowName.toString() + ' SECTION.' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + ' SECTION.', replaceStr3);
      }
      if (this.codeString.indexOf(this.flowName.toString() + ' begsr') > 0){
        const replaceStr4 = '<span id="canvasScroll">' +
          this.flowName.toString() + ' begsr' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + ' begsr', replaceStr4);
      }
      if (this.codeString.indexOf('begsr ' + this.flowName.toString()) > 0) {
        const replaceStr5 = '<span id="canvasScroll">' +
          'begsr ' + this.flowName.toString() + '</span>';
        this.codeString = this.codeString.replace('begsr ' + this.flowName.toString(), replaceStr5);
      }
      if (this.codeString.indexOf('DEFINE SUBROUTINE ' + this.flowName.toString()) > 0) {
        const replaceStr6 = '<span id="canvasScroll">' +
        'DEFINE SUBROUTINE ' + this.flowName.toString()+ '</span>';
        this.codeString = this.codeString.replace('DEFINE SUBROUTINE ' + this.flowName.toString(), replaceStr6);
        // console.log(replaceStr6);
      }
      if (this.codeString.indexOf(this.flowName.toString() + 'begsr') > 0) {
        const replaceStr6 = '<span id="canvasScroll">' +
          this.flowName.toString() + 'begsr' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + 'begsr', replaceStr6);
      }
      if (this.codeString.indexOf(this.flowName.toString().toUpperCase() + '.') > 0) {
        const replaceStr7 = '<span id="canvasScroll">' +
          this.flowName.toString().toUpperCase() + '.' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString().toUpperCase() + '.', replaceStr7);
      }


      document.getElementById('canvasCode').innerHTML = this.codeString;
      (document.getElementById('canvasCode') as HTMLInputElement).style.fontFamily = 'Courier';

      setTimeout(() => {
        const elmnt = document.getElementById('canvasScroll');
        try {
          elmnt.scrollIntoView();
        } catch (e) {
          console.log(e + 'Para expansion not found');
        }
      }, 1100);
    }, error => {
      this.errormessage = 'Code not available for current component';
      (document.getElementById('canvasCode') as HTMLInputElement).innerHTML = this.errormessage;
});

      // // $(window).scrollTop($('*:contains("' + this.selectedComponent + '"):last').offset().top);
      // $('#canvasCode').html($('#canvasCode').html().replace(this.selectedComponent,
      //     '<a id="scrollTo"></a>' + this.selectedComponent));
      // $('canvasCode').animate({scrollTop: $('#scrollTo').offset().top}, 500);​​​​​​​​​​​​
      // $('#canvasCode').scrollTop($(this.selectedComponent).offset().top);
  }
  
}



