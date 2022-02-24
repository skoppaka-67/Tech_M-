import { Component, OnInit, Input } from '@angular/core';
import * as shape from 'd3-shape';
import { NgxGraphModule } from '@swimlane/ngx-graph';
import { DataService } from '../data.service';
import * as html2canvas from 'html2canvas';
import { NgbModalConfig, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import 'zone.js/dist/zone';
// import html2canvas from 'html2canvas';
import * as domtoimage from 'dom-to-image';
import {PrintService} from '../../print.service';
// import * as jsPDF from 'jspdf';

declare var pdfMake: any;
declare var flowchart: any;

@Component({
    selector: 'app-bs-component',
    templateUrl: './bs-component.component.html',
    styleUrls: ['./bs-component.component.scss']
})
export class BsComponentComponent implements OnInit {
  // curve = shape.curveLinear;
  constructor( public dataservice: DataService, config: NgbModalConfig, private modalService: NgbModal,
    public printService: PrintService) {
    config.backdrop = 'static';
    config.keyboard = false;
  }
  name = 'Graph';
  flowName = '';
  content2: string;
  content4: string;
  selectedComponent = '';
  element = '';
  errormessage = '';
  applicationTypeList: any[] = [];
  programNameList: any[] = [];
  selectedApplication = '';
  // content = '';
  // @Input() name: string;
  content = '';
  content3: any[];
  // showLoader:boolean=true;
  hierarchialGraph = {nodes: [], links: []};
  view = [5000, 6000];
  compName: string;
 // orientation="LR";
  // view: any[];
 // width = 10;
 // height = 10;

  curve = shape.curveBundle.beta(1);
  componentList: any[] = [];
  // selectedComponent = '';
  single: any[];
  multi: any[];
  docDefinition: any;
  nodesStr = '';
  compStr = '';
  linksStr = '';
  paraname = '';
  codeString = '';
 // downloadPdf() {
    // let doc = new jsPDF();
    // doc.addHTML(document.getElementById("canvas"), function() {
    //    doc.save("test.pdf");
    // });
// }

open(content, flowName) {
  this.modalService.open(content, flowName);
  // $('body').css('overflow-y', 'hidden');
  this.flowName = flowName.name;
  // modal popup chart code start
  // this.dataservice.getFlowChartContent().subscribe(res => {
    (document.getElementById('flowChartBtn') as HTMLInputElement).disabled = true;
    this.compName = this.selectedComponent;
  this.dataservice.getFlowChartContent(this.selectedComponent, this.flowName).subscribe(res => {
    if (res.status === 'available') {
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'hidden';
      this.content2 = res.option;
      this.content2 = this.content2.toString().replace(/<br>/g, '\n');
      const chart = flowchart.parse(this.content2);
      


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
      
      var svg = document.getElementsByTagName('svg')[1];
      svg.setAttribute('width', '1000px');
    } else if (res.status === 'unavailable') {
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'visible';
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.color = 'red';
      (document.getElementById('flowChartErrMsg') as HTMLInputElement).innerHTML = 'Data is not available for selected para!!';
    }
  });
}


  public ngOnInit(): void {
    window.scrollTo(0, 0);
    // this.getComponentList();
    this.applicationList();
    (document.getElementById('processErrMsg') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'hidden';
    // (document.getElementById('flowChartBtn') as HTMLInputElement).disabled = false;
    // (document.getElementById('paraCodeBtn') as HTMLInputElement).style.visibility = 'hidden';
  }

  // downloadChart() {
  //   const elementToPrint = document.getElementById('canvasCode'); // The html element to become a pdf
  //   const pdf = new jsPDF('p', 'pt', 'a4');
  //   pdf.addHTML(elementToPrint, () => {
  //       pdf.save('test.pdf');
  //   });
  // }

  getComponentList() {
    this.dataservice.getComponentList().subscribe(res => {
        this.componentList = res.program_list;
    });
  }
  applicationList() {
    this.dataservice.getApplicationList().subscribe(res => {
      this.applicationTypeList = res.application_list;
      console.clear();
  });
  }
  applicationTypeOnchange(event: any){
    this.getProgramNameList(event.target.value);
    this.selectedApplication = event.target.value;
  }
  getProgramNameList(selectedApplication){
    this.dataservice.getProgramNameList(selectedApplication).subscribe(res => {
      this.programNameList = res.component_list;
  });
  }

  programNameOnchange(event: any){
    this.selectedComponent = event.target.value;
  }

  onClick(data): void {
      const _str = data.name;
      alert(_str);
}
  onSubmit() {
      // console.log("selectedComponent::"+this.selectedComponent);
    // this.showLoader = true;
      if (this.selectedComponent === '') {
          this.hierarchialGraph = {nodes: [], links: []};
          (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'hidden';
      } else {
      this.dataservice.getProcedureFlow(this.selectedComponent).subscribe(res => {
          if (res.nodes.length !== 0) {
            (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'visible';
            (document.getElementById('processErrMsg') as HTMLInputElement).style.visibility = 'hidden';
            (document.getElementById('procFlow') as HTMLInputElement).style.visibility = 'visible';
            this.hierarchialGraph = res;
          // this.showLoader = false;
        // console.log(this.componentList);
        } else {
          // if chart data not available.
          (document.getElementById('downloadBtn') as HTMLInputElement).style.visibility = 'hidden';
          (document.getElementById('processErrMsg') as HTMLInputElement).style.visibility = 'visible';
          (document.getElementById('processErrMsg') as HTMLInputElement).style.color = 'red';
          (document.getElementById('processErrMsg') as HTMLInputElement).innerText = 'Data not available for selected program!';
          (document.getElementById('procFlow') as HTMLInputElement).style.visibility = 'hidden';
        }
      });
    }
    // this.showLoader = false;
  }
  onChange(component: string) {
    if (component === '') {
        this.selectedComponent = '';
    } else {
        this.selectedComponent = component;
    }
  }
  printData() {
    window.print();
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

  showParaCode() {
    (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'hidden';

    (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
    (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
    (document.getElementById('paraCodeBtn') as HTMLInputElement).disabled = true;
    
    (document.getElementById('dwnBtn') as HTMLInputElement).style.visibility = 'hidden';
    
    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'visible';
    (document.getElementById('canvas') as HTMLInputElement).style.visibility = 'hidden';
    // (document.getElementById('canvasTwo') as HTMLInputElement).style.visibility = 'hidden';

    (document.getElementById('canvas') as HTMLInputElement).style.height = '0%';
    // (document.getElementById('canvasTwo') as HTMLInputElement).style.height = '0%';
    (document.getElementById('canvasCode') as HTMLInputElement).style.height = '100%';

    (document.getElementById('flowChartBtn') as HTMLInputElement).disabled = false;
    // (document.getElementById('flowChartBtn2') as HTMLInputElement).disabled = false;
    (document.getElementById('paraCodeBtn') as HTMLInputElement).disabled = true;
    this.compName = this.selectedComponent;
    this.dataservice.getComponentCode(this.selectedComponent, 'COBOL').subscribe(res => {
      this.codeString = res.codeString;

      /*this.codeString = this.codeString
      .replace(/\"/g, '"')
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
      
      if (this.codeString.indexOf(this.flowName.toString() + '.') > 0) {
        if (this.codeString.indexOf('PERFORM ' + this.flowName.toString() + '.') > 0) {
        } else {
          const replaceStr = '<span id="canvasScroll">' +
          this.flowName.toString() + '.' + '</span>';
          this.codeString = this.codeString.replace(this.flowName.toString() + '.', replaceStr);
        }
      }
      if (this.codeString.indexOf(this.flowName.toString() + ' section.') > 0) {
        const replaceStr1 = '<span id="canvasScroll">' +
          this.flowName.toString() + ' section.' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + ' section.', replaceStr1);
        // console.log(replaceStr1);
      }
      if (this.codeString.indexOf(this.flowName.toString() + ' Section.') > 0) {
        const replaceStr2 = '<span id="canvasScroll">' +
          this.flowName.toString() + ' Section.' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + ' Section.', replaceStr2);
        // console.log(replaceStr2);
      }
      if (this.codeString.indexOf(this.flowName.toString() + ' SECTION.') > 0) {
        const replaceStr3 = '<span id="canvasScroll">' +
          this.flowName.toString() + ' SECTION.' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + ' SECTION.', replaceStr3);
        // console.log(replaceStr3);
      }
      if (this.codeString.indexOf('DEFINE SUBROUTINE ' + this.flowName.toString()) > 0) {
        const replaceStr6 = '<span id="canvasScroll">' +
        'DEFINE SUBROUTINE ' + this.flowName.toString()+ '</span>';
        this.codeString = this.codeString.replace('DEFINE SUBROUTINE ' + this.flowName.toString(), replaceStr6);
        // console.log(replaceStr6);
      }
      if (this.codeString.indexOf(this.flowName.toString() + ' begsr') > 0){
        const replaceStr4 = '<span id="canvasScroll">' +
          this.flowName.toString() + ' begsr' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + ' begsr', replaceStr4);
        // console.log(replaceStr4);
      }
      if (this.codeString.indexOf('begsr ' + this.flowName.toString()) > 0) {
        const replaceStr5 = '<span id="canvasScroll">' +
          'begsr ' + this.flowName.toString() + '</span>';
        this.codeString = this.codeString.replace('begsr ' + this.flowName.toString(), replaceStr5);
        // console.log(replaceStr5);
      }
      if (this.codeString.indexOf(this.flowName.toString() + 'begsr') > 0) {
        const replaceStr7 = '<span id="canvasScroll">' +
          this.flowName.toString() + 'begsr' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString() + 'begsr', replaceStr7);
        // console.log(replaceStr7);
      }
      if (this.codeString.indexOf(this.flowName.toString().toUpperCase() + '.') > 0) {
        const replaceStr8 = '<span id="canvasScroll">' +
          this.flowName.toString().toUpperCase() + '.' + '</span>';
        this.codeString = this.codeString.replace(this.flowName.toString().toUpperCase() + '.', replaceStr8);
        // console.log(replaceStr8);
      }
      if (this.codeString.indexOf('PROCEDURE ' + this.flowName.toString()) > 0) {
        const replaceStr9 = '<span id="canvasScroll">' +
          'PROCEDURE ' + this.flowName.toString() + '</span>';
        this.codeString = this.codeString.replace('PROCEDURE ' + this.flowName.toString(), replaceStr9);
        // console.log(replaceStr5);
      }
      if (this.codeString.indexOf('FUNCTION ' + this.flowName.toString()) > 0) {
        const replaceStr10 = '<span id="canvasScroll">' +
          'FUNCTION ' + this.flowName.toString() + '</span>';
        this.codeString = this.codeString.replace('FUNCTION ' + this.flowName.toString(), replaceStr10);
        // console.log(replaceStr5);
      }
      if (this.codeString.indexOf('TRIGGER ' + this.flowName.toString()) > 0) {
        const replaceStr11 = '<span id="canvasScroll">' +
          'TRIGGER ' + this.flowName.toString() + '</span>';
        this.codeString = this.codeString.replace('TRIGGER ' + this.flowName.toString(), replaceStr11);
        // console.log(replaceStr5);
      }
      if (this.codeString.indexOf('PACKAGE ' + this.flowName.toString()) > 0) {
        const replaceStr12 = '<span id="canvasScroll">' +
          'PACKAGE ' + this.flowName.toString() + '</span>';
        this.codeString = this.codeString.replace('PACKAGE ' + this.flowName.toString(), replaceStr12);
        // console.log(replaceStr5);
      }
      //lower
      if (this.codeString.indexOf('procedure ' + this.flowName.toString().toLowerCase()) > 0) {
        const replaceStr9 = '<span id="canvasScroll">' +
          'procedure ' + this.flowName.toString() + '</span>';
        this.codeString = this.codeString.replace('procedure ' + this.flowName.toString(), replaceStr9);
        // console.log(replaceStr5);
      }
      if (this.codeString.indexOf('function ' + this.flowName.toString()) > 0) {
        const replaceStr10 = '<span id="canvasScroll">' +
          'function ' + this.flowName.toString() + '</span>';
        this.codeString = this.codeString.replace('function ' + this.flowName.toString(), replaceStr10);
        // console.log(replaceStr5);
      }
      if (this.codeString.indexOf('trigger ' + this.flowName.toString()) > 0) {
        const replaceStr11 = '<span id="canvasScroll">' +
          'trigger ' + this.flowName.toString() + '</span>';
        this.codeString = this.codeString.replace('trigger ' + this.flowName.toString(), replaceStr11);
        // console.log(replaceStr5);
      }
      if (this.codeString.indexOf('package ' + this.flowName.toString()) > 0) {
        const replaceStr12 = '<span id="canvasScroll">' +
          'package ' + this.flowName.toString() + '</span>';
        this.codeString = this.codeString.replace('package ' + this.flowName.toString(), replaceStr12);
        // console.log(replaceStr5);
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

  showExpandedCode(){
    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('canvasCode') as HTMLInputElement).style.height = '0%';
    (document.getElementById('canvas') as HTMLInputElement).style.height = '0%';
    (document.getElementById('canvas') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'visible';
    (document.getElementById('expandedCode') as HTMLInputElement).style.height = '100%';

    (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = true;
    (document.getElementById('paraCodeBtn') as HTMLInputElement).disabled = false;
    (document.getElementById('flowChartBtn') as HTMLInputElement).disabled = false;

    (document.getElementById('dwnBtn') as HTMLInputElement).style.visibility = 'hidden';

    this.dataservice.getExpandedComponentCode(this.compName, 'COBOL').subscribe(res => {
      this.codeString = res.codeString;
     /* this.codeString = this.codeString
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

      if (this.codeString.indexOf(this.flowName.toString() + '.') > 0) {
        if (this.codeString.indexOf('PERFORM ' + this.flowName.toString() + '.') > 0) {
        } else {
          const replaceStr = '<span id="canvasScroll">' +
          this.flowName.toString() + '.' + '</span>';
          this.codeString = this.codeString.replace(this.flowName.toString() + '.', replaceStr);
        }
      }
        if (this.codeString.indexOf(this.flowName.toString() + ' section.') > 0) {
          const replaceStr1 = '<span id="expCanvasScroll">' +
            this.flowName.toString() + ' section.' + '</span>';
          this.codeString = this.codeString.replace(this.flowName.toString() + ' section.', replaceStr1);
        }
        if (this.codeString.indexOf(this.flowName.toString() + ' Section.') > 0) {
          const replaceStr2 = '<span id="expCanvasScroll">' +
            this.flowName.toString() + ' Section.' + '</span>';
          this.codeString = this.codeString.replace(this.flowName.toString() + ' Section.', replaceStr2);
        }
        if (this.codeString.indexOf(this.flowName.toString() + ' SECTION.') > 0) {
          const replaceStr3 = '<span id="expCanvasScroll">' +
            this.flowName.toString() + ' SECTION.' + '</span>';
          this.codeString = this.codeString.replace(this.flowName.toString() + ' SECTION.', replaceStr3);
        }
        if (this.codeString.indexOf(this.flowName.toString() + ' begsr') > 0){
          const replaceStr4 = '<span id="expCanvasScroll">' +
            this.flowName.toString() + ' begsr' + '</span>';
          this.codeString = this.codeString.replace(this.flowName.toString() + ' begsr', replaceStr4);
        }
        if (this.codeString.indexOf('begsr ' + this.flowName.toString()) > 0) {
          const replaceStr5 = '<span id="expCanvasScroll">' +
            'begsr ' + this.flowName.toString() + '</span>';
          this.codeString = this.codeString.replace('begsr ' + this.flowName.toString(), replaceStr5);
        }
        if (this.codeString.indexOf(this.flowName.toString() + 'begsr') > 0) {
          const replaceStr6 = '<span id="expCanvasScroll">' +
            this.flowName.toString() + 'begsr' + '</span>';
          this.codeString = this.codeString.replace(this.flowName.toString() + 'begsr', replaceStr6);
        }
        if (this.codeString.indexOf(this.flowName.toString().toUpperCase() + '.') > 0) {
          const replaceStr7 = '<span id="expCanvasScroll">' +
            this.flowName.toString().toUpperCase() + '.' + '</span>';
          this.codeString = this.codeString.replace(this.flowName.toString().toUpperCase() + '.', replaceStr7);
        }

        document.getElementById('expandedCode').innerHTML = this.codeString;
        (document.getElementById('expandedCode') as HTMLInputElement).style.fontFamily = 'Courier';
  
        setTimeout(() => {
          const elmnt = document.getElementById('expCanvasScroll');
          try {
            elmnt.scrollIntoView();
          } catch (e) {
            console.log(e + 'Para expansion not found');
          }
        }, 1100);

    }, error => {
      this.errormessage = 'Code not available for current component';
      (document.getElementById('expandedCode') as HTMLInputElement).innerHTML = this.errormessage;
      const elmnt = document.getElementById('expandedCode');
          try {
            elmnt.scrollIntoView();
          } catch (e) {
            console.log(e + 'Para expansion not found');
          }
  });
  }
  showCode(){
    (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'visible';
    (document.getElementById('canvasCode') as HTMLInputElement).style.height = '100%';
    (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;
    (document.getElementById('paraCodeBtn') as HTMLInputElement).disabled = true;

  }
  showFlowChart() {

    (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'visible';

    (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
    // (document.getElementById('canvasTwo') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('canvas') as HTMLInputElement).style.visibility = 'visible';

    (document.getElementById('dwnBtn') as HTMLInputElement).style.visibility = 'visible'; // changed for now

    (document.getElementById('flowChartBtn') as HTMLInputElement).disabled = true;
    // (document.getElementById('flowChartBtn2') as HTMLInputElement).disabled = false;
    (document.getElementById('paraCodeBtn') as HTMLInputElement).disabled = false;


    (document.getElementById('expandedCode') as HTMLInputElement).style.visibility = 'hidden';
    (document.getElementById('expandedCode') as HTMLInputElement).style.height = '0%';
    (document.getElementById('expandedCodeBtn') as HTMLInputElement).disabled = false;

    (document.getElementById('canvas') as HTMLInputElement).style.height = '100%';
    // (document.getElementById('canvasTwo') as HTMLInputElement).style.height = '0%';
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
  // showFlowChartTwo(){
  //   this.dataservice.getFlowChartTwoContent(this.selectedComponent, this.flowName).subscribe(res => {
  //     if (res.status === 'available') {
  //       (document.getElementById('canvasTwo') as HTMLInputElement).innerHTML = '';
  //       (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'hidden';
  //       this.content4 = res.option;
  //       this.content4 = this.content4.toString().replace(/<br>/g, '\n');
  //       // console.log(this.content4);
  //       const chart1 = flowchart.parse(this.content4);
  //       chart1.drawSVG('canvasTwo', {
  //           'x': 15,
  //           'y': 10,
  //           'line-width': 1,
  //           'line-length': 1,
  //           'text-margin': 15,
  //           'font-size': 14,
  //           'font': 'normal',
  //           'font-family': 'Helvetica',
  //           'font-weight': 'normal',
  //           'font-color': 'black',
  //           'line-color': 'black',
  //           'element-color': 'black',
  //           'fill': 'white',
  //           'yes-text': 'yes',
  //          'no-text': 'no',
  //           'arrow-end': 'block',
  //           'symbols': {
  //             'start': {
  //               'font-color': 'black',
  //               'element-color': 'black',
  //               'fill': 'white'
  //             },
  //             'end': {
  //               'class': 'end-element'
  //             }
  //           },
  //           'flowstate': {
  //             'past': {
  //                 'fill': '#99cc00',
  //                     'font-size': 12
  //             },
  //                 'current': {
  //                 'fill': 'white',
  //                     'font-color': 'black' // ,
  //                     // 'font-weight': 'bold'
  //             },
  //                 'future': {
  //                 'fill': '#9933ff'
  //           },
  //                 'request': {
  //                 'fill': 'ffffff'
  //             },
  //                 'invalid': {
  //                 'fill': '#444444'
  //             },
  //                 'approved': {
  //                 'fill': '#00ccff',
  //                     'font-size': 12 // ,
  //                     // 'yes-text': 'APPROVED',
  //                     // 'no-text': 'n/a'
  //             },
  //             'io': {
  //             'fill': '#cccccc',
  //                 'font-size': 12
  //         },
  //                 'rejected': {
  //                 'fill': '#ff471a',
  //                     'font-size': 12 // ,
  //                     // 'yes-text': 'n/a',
  //                     // 'no-text': 'REJECTED'
  //             }
  //       }
  //       });
  //   } else if (res.status === 'unavailable') {
  //     (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'visible';
  //     (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.color = 'red';
  //     (document.getElementById('flowChartErrMsg') as HTMLInputElement).innerHTML = 'Data is not available for selected para!!';
  //   }
  //   });
  //   (document.getElementById('flowChartErrMsg') as HTMLInputElement).style.visibility = 'visible';

  //   (document.getElementById('canvasCode') as HTMLInputElement).style.visibility = 'hidden';
  //   (document.getElementById('canvas') as HTMLInputElement).style.visibility = 'hidden';
  //   (document.getElementById('canvasTwo') as HTMLInputElement).style.visibility = 'visible';

  //   (document.getElementById('dwnBtn') as HTMLInputElement).style.visibility = 'visible';

  //   (document.getElementById('flowChartBtn2') as HTMLInputElement).disabled = true;
  //   (document.getElementById('flowChartBtn') as HTMLInputElement).disabled = false;
  //   (document.getElementById('paraCodeBtn') as HTMLInputElement).disabled = false;

  //   (document.getElementById('canvasTwo') as HTMLInputElement).style.height = '100%';
  //   (document.getElementById('canvas') as HTMLInputElement).style.height = '0%';
  //   (document.getElementById('canvasCode') as HTMLInputElement).style.height = '0%';
  //   setTimeout(() => {
  //     const elmnt = document.getElementById('canvasTwo');
  //     try {
  //       elmnt.scrollIntoView();
  //     } catch (e) {
  //       console.log(e + 'No flowchart found');
  //     }
  //   }, 1100);
  // }
  export2Doc() {
    // this.element = 'procFlow';
    // let filename = this.selectedComponent;
    // tslint:disable-next-line:max-line-length
    // const preHtml = '<html xmlns:o=\'urn:schemas-microsoft-com:office:office\' xmlns:w=\'urn:schemas-microsoft-com:office:word\' xmlns=\'http://www.w3.org/TR/REC-html40\'><head><meta charset=\'utf-8\'><title>Export HTML To Doc</title></head><body>';
    // const postHtml = '</body></html>';
    // const html = preHtml + (document.getElementById(this.element) as HTMLElement).innerHTML + postHtml;
    // const blob = new Blob(['\ufeff', html], {
    //     type: 'application/msword'
    // });
    // // Specify link url
    // const url = 'data:application/vnd.ms-word;charset=utf-8,' + encodeURIComponent(html);
    // // Specify file name
    // filename = filename ? filename + '.doc' : 'document.doc';
    // // Create download link element
    // const downloadLink = document.createElement('a');
    // document.body.appendChild(downloadLink);
    // if (navigator.msSaveOrOpenBlob ) {
    //     navigator.msSaveOrOpenBlob(blob, filename);
    // } else {
    //     // Create a link to the file
    //     downloadLink.href = url;
    //     // Setting the file name
    //     downloadLink.download = filename;
    //     // triggering the function
    //     downloadLink.click();
    // }
    // document.body.removeChild(downloadLink);


    // function downloadInnerHtml(filename, elId) {
    //   const elHtml = document.getElementById(elId).innerHTML;
    //   const link = document.createElement('a');
    //   link.setAttribute('download', filename);
    //   link.setAttribute('href', 'data:' + 'text/doc' + ';charset=utf-8,' + encodeURIComponent(elHtml));
    //   link.click();
    //  }
    //  const fileName =  this.selectedComponent + '.doc'; // You can use the .txt extension if you want
    //  downloadInnerHtml(fileName, 'procFlow');


    const node = document.getElementById('procFlow');
    const filename = (document.getElementById('cboSelect') as HTMLInputElement).value;

    // // only html content is saved as word document
    // let link, blob, url;
    // blob = new Blob(['\ufeff', document.getElementById('procFlow').innerHTML], {
    //       type: 'application/msword'
    // });
    // url = URL.createObjectURL(blob);
    // link = document.createElement('a');
    // link.href = url;
    // link.download = filename;  // default name without extension
    // document.body.appendChild(link);
    // if (navigator.msSaveOrOpenBlob ) {
    //   navigator.msSaveOrOpenBlob( blob, filename + '.doc'); // IE10-11
    // } else {
    //   link.click();  // other browsers
    // }
    // document.body.removeChild(link);

    domtoimage.toPng(node).then(function (dataUrl) {

      // works - save as png
       const img = new Image();
        img.src = dataUrl;
        const link = document.createElement('a');
        link.setAttribute('href', img.src);
        link.setAttribute('download', (document.getElementById('cboSelect') as HTMLInputElement).value + '.png');
        link.click();

        // not working
        // domtoimage.toBlob(node).then(function(blob) {
        //   // window.saveAs(blob, filename + '.docx');
        // const link = document.createElement('a');
        // link.href = blob;
        // link.setAttribute('download', filename + '.docx');
        // link.click();

        // no download
        // const docx = document.createElement('doc');
        // docx.setAttribute('href', dataUrl);
        // docx.setAttribute('download', filename + '.docx');
        // docx.click();

        // not working - empty / corrupted file
        // domtoimage.toBlob(node).then(function(blob) {
        //   const urlDocx = URL.createObjectURL(blob);
        //   const link1 = document.createElement('a');
        //   link1.href = urlDocx;
        //   link1.download = filename + '.docx';
        //   link1.click();
    }).catch(function (error) {
        console.error('oops, something went wrong!', error);
    });
  }
}
