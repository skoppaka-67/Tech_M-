import { Component, OnInit } from '@angular/core';
import { ChartOptions } from 'chart.js';
import { routerTransition } from '../../router.animations';
import { ChartsModule as Ng2Charts } from 'ng2-charts';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
declare var pdfMake: any;
import html2canvas from 'html2canvas';
// import html2canvas from 'html2canvas';
import { Router, NavigationEnd } from '@angular/router';
import * as domtoimage from 'dom-to-image';
import * as pluginDataLabels from 'chartjs-plugin-datalabels';
import { reduce } from 'rxjs/operators';

@Component({
    selector: 'app-dashboard',
    templateUrl: './dashboard.component.html',
    styleUrls: ['./dashboard.component.scss'],
    animations: [routerTransition()]
})
export class DashboardComponent implements OnInit {

    constructor(public dataservice: DataService, public router: Router) {}
    title = 'Dashboard';

    public resultStatus: string;
    total_deadLine: number;
    total: number;
    public barChartPlugins = [pluginDataLabels];
    dataSets: any[] = [];
    pieChartDs: any;
    OverAllUploadStatus: any;
    OverAllUploadStatus_flag: any;
    doughnutChartDs: any;
    public alerts: Array<any> = [];
    public doughnutChartData: number[] = [];
    public doughnutChartRuleData: number[] = [];
    public doughnutChartLabels: string[] = ['Count of Orphan in %', 'Count of Component Name in %'];
    // public doughnutChartLabels: string[] = [];
    public doughnutChartRuleLabels: string[] = [];
    public doughnutChartType: string;
    public doughnutChartRuleType: string;
    public pieChartLabels = ['Total Dead Lines of Code in %', 'Total Active Lines of Code in %'];
    public pieChartType: string;
    public chartType = '';
    public pieChartData: number[] = [];
    public chartDatasets: Array<any> = [{data: []}];
    public horizontalChartLabels: string[] = [];
    // lineChart
    public lineChartData: Array<any> = [{data: []}];
    public line2ChartData: Array<any> = [{data: []}];
    public lineChartLabels: Array<any> = [];
    public line2ChartLabels: Array<any> = [];
    public lineChData: any[] = [];

    //
    public lineChart2Data: Array<any> = [{data: []}];
    public lineChart2Labels: Array<any> = [];
    public lineChart2Legend: boolean;
    public lineChart2Type: string;


    public barChart2Data: any[] = [{data: [], label: [], backgroundColor: []}];
    public barChart2Colors = [{backgroundColor: []}];
    public barChart2Labels: string[] = [];
    public barChart2LabelHeader: string[] = [];
    public barChart2Legend: boolean;
    public barChart2Type = '';

    public barChart3Data: any[] = [{data: [], label: [], backgroundColor: []}];
    public barChart3Colors = [{backgroundColor: []}];
    public barChart3Labels: string[] = [];
    public barChart3LabelHeader: string[] = [];
    public barChart3Legend: boolean;
    public barChart3Type = '';

    public barChartColors = [{backgroundColor: []}]; // changed from private
    public barChartLabels: string[] = [];
    public barChartLabelHeader: string[] = [];
    public barChartType = '';
    public barChartLegend: boolean;
    public barChartData: any[] = [{data: [], label: [], backgroundColor: []}];
    private tempArr: number[] = [];
    public map: Map<number, string> = new Map<number, string>();
    public polarChartColors: Array<any> = [
        {
            backgroundColor: [
              'rgba(255, 0, 0, 0.8)', 'rgba(0, 255,200, 0.8)', 'rgba(200, 0, 200, 0.6)',
              'rgba(0, 255, 0, 0.6)', 'rgba(20, 56, 114,0.6)'],
            borderColor: [
              'rgba(255, 0, 0, 0.8)', 'rgba(0, 255,200, 0.8)', 'rgba(200, 0, 200, 0.6)',
              'rgba(0, 255, 0, 0.6)', 'rgba(20, 56, 114,0.6)']
        }
    ];

    public lineChartColors: Array<any> = [
        {
            // grey
            backgroundColor: 'rgba(148,159,177,1)',
            borderColor: 'rgba(148,159,177,1)',
            pointBackgroundColor: 'rgba(148,159,177,1)',
            pointBorderColor: '#144593',
            pointHoverBackgroundColor: '#144593',
            pointHoverBorderColor: 'rgba(148,159,177,0.8)'
        },
        {
            // dark grey
            backgroundColor: 'rgba(77,83,96,1)',
            borderColor: 'rgba(77,83,96,1)',
            pointBackgroundColor: 'rgba(77,83,96,1)',
            pointBorderColor: '#144593',
            pointHoverBackgroundColor: '#144593',
            pointHoverBorderColor: 'rgba(77,83,96,1)'
        },
        {
            // grey
            backgroundColor: 'rgba(148,159,177,0.2)',
            borderColor: 'rgba(148,159,177,1)',
            pointBackgroundColor: 'rgba(148,159,177,1)',
            pointBorderColor: '#fff',
            pointHoverBackgroundColor: '#fff',
            pointHoverBorderColor: 'rgba(148,159,177,0.8)'
        }
    ];
    public lineChart2Colors: Array<any> = [
      {
          // grey
          backgroundColor: 'rgba(204,204,204,1)',
          borderColor: 'rgba(204,204,204,1)',
          pointBackgroundColor: 'rgba(204,204,204,1)',
          pointBorderColor: '#ff0000',
          pointHoverBackgroundColor: '#ff0000',
          pointHoverBorderColor: 'rgba(204,204,204,0.8)'
      },
      {
          // dark grey
          backgroundColor: 'rgba(238,238,238,1)',
          borderColor: 'rgba(238,238,238,1)',
          pointBackgroundColor: 'rgba(238,238,238,1)',
          pointBorderColor: '#ff0000',
          pointHoverBackgroundColor: '#ff0000',
          pointHoverBorderColor: 'rgba(238,238,238,1)'
      },
      {
          // grey
          backgroundColor: 'rgba(204,204,204,0.2)',
          borderColor: 'rgba(204,204,204,1)',
          pointBackgroundColor: 'rgba(204,204,204,1)',
          pointBorderColor: '#ff0000',
          pointHoverBackgroundColor: '#ff0000',
          pointHoverBorderColor: 'rgba(204,204,204,0.8)'
      }
  ];
    public lineChartLegend: boolean;
    public lineChartType: string;
    public line2ChartLegend: boolean;
    public line2ChartType: string;

    public pieColors = [
        {
          backgroundColor: ['rgba(255,204,51,1)', 'rgba(0,204,102,1)']
        }
    ];
    public doughnutColors = [
        {
          // backgroundColor: ['rgba(51,0,51,1)', 'rgba(153,0,51,0.9)']
          backgroundColor: ['rgba(153,204,0,1)', 'rgba(0,153,204,1)']
        }
    ];
    public doughnutRuleColors = [
    //   {
    //  // backgroundColor: ['rgba(51,0,51,1)', 'rgba(153,0,51,0.9)']
    // //  backgroundColor: ['rgba(153,204,0,1)', 'rgba(0,153,204,1)']
    //   }
      {
        backgroundColor: [
          'rgba(51,0,51,1)',
          'rgba(153,0,51,0.9)',
          'rgba(255, 99, 132, 1)',
          'rgba(54, 162, 235, 1)',
          'rgba(255, 206, 86, 1)',
          'rgba(75, 192, 192, 1)',
          'rgba(153, 102, 255, 1)',
          'rgba(255, 159, 64, 1)',
          'rgba(153, 0, 102, 1)',
          'rgba(153, 102, 51, 1)',
          'rgba(51, 102, 204, 1)',
          'rgba(0, 102, 51, 1)'
        ]
      }
    ];

    public chartColors: Array<any> = [
      {
           backgroundColor: [
           'rgba(255, 99, 132, 1)',
           'rgba(54, 162, 235, 1)',
           'rgba(255, 206, 86, 1)',
           'rgba(75, 192, 192, 1)',
           'rgba(153, 102, 255, 1)',
           'rgba(255, 159, 64, 1)',
           'rgba(153, 0, 102, 1)',
           'rgba(153, 102, 51, 1)',
           'rgba(51, 102, 204, 1)',
           'rgba(0, 102, 51, 1)'
           ],
             borderWidth: 0,
      }
     ];

    public chartOptions: any = {
      scaleShowVerticalLines: false,
      responsive: true,
      AnimationEffect: true,
      plugins: {
        datalabels: {
          anchor: 'center',
          align: 'center'
        }
      },
      scales: {
          xAxes: [{
              gridLines: {
                  color: 'rgba(0, 0, 0, 0.1)'
              },ticks: {
                beginAtZero : true,
                // suggestedMax: 8
              }
          }
        ],
          yAxes: [{
              gridLines: {
                  color: 'rgba(0, 0, 0, 0.1)'
              }
          }
          ]
      }
    };

    public polarChartOptions = {
        startAngle: -Math.PI / 4,
        legend: {
          position: 'left'
        },
        animation: {
          animateRotate: false
        }
    };

    dtOptions: DataTables.Settings = {};
    dtElement: DataTableDirective;

    single: any[];
    multi: any[];
    docDefOrphan: any;
    docDefRules: any;
    docDefDeadline: any;
    docDefTop10AppTechLoc: any;
    docDefAppwiseInOutBound: any;
    docDefAppwiseRules: any;
    docDefTechvsLoc: any;
    docDefTop5TechvsDead: any;
    docDefAppwiseCyclo: any;
    docDefTop5TechvsLoc: any;
    chartdesc: any;

     // bar chart
     public barChartOptions: any = {
      scaleShowVerticalLines: false,
      responsive: true,
      AnimationEffect: true,
      plugins: {
        datalabels: {
          anchor: 'end',
          align: 'end'
        }
      },
      scales: {
          xAxes: [{
              gridLines: {
                  color: 'rgba(0, 0, 0, 0.2)',
              },
              ticks: {
                  autoSkip: false,
                  stepSize: 1,
                  min: 0
              }
          }],
          yAxes: [{
              gridLines: {
                  color: 'rgba(0, 0, 0, 0.1)',
              }
          }
          ]
      }

    };

    public barChart2Options: any = {
      scaleShowVerticalLines: false,
      responsive: true,
      AnimationEffect: true,
      plugins: {
        datalabels: {
          anchor: 'end',
          align: 'end'
        }
      },
      scales: {
          xAxes: [{
              gridLines: {
                  color: 'rgba(0, 0, 0, 0.2)',
              },
              ticks: {
                  autoSkip: false,
                  stepSize: 1,
                  min: 0
              }
          }],
          yAxes: [{
              gridLines: {
                  color: 'rgba(0, 0, 0, 0.1)',
              }
          }
          ]
      }

    };
    public barChart3Options: any = {
      scaleShowVerticalLines: false,
      responsive: true,
      AnimationEffect: true,
      plugins: {
        datalabels: {
          anchor: 'end',
          align: 'end'
        }
      },
      scales: {
          xAxes: [{
              gridLines: {
                  color: 'rgba(0, 0, 0, 0.2)',
              },
              ticks: {
                  autoSkip: false,
                  stepSize: 1,
                  min: 0
              }
          }],
          yAxes: [{
              gridLines: {
                  color: 'rgba(0, 0, 0, 0.1)',
              }
          }
          ]
      }

    };

    // public barChartLabels: string[] = [
    //     '2006',
    //     '2007',
    //     '2008',
    //     '2009',
    //     '2010',
    //     '2011',
    //     '2012'
    // ];
    // public barChartType: string;
    // public barChartLegend: boolean;

    // public barChartData: any[] = [
    //     { data: [65, 59, 80, 81, 56, 55, 40], label: 'Series A' },
    //     { data: [28, 48, 40, 19, 86, 27, 90], label: 'Series B' }
    // ];

    public lineChartOptions: any = {
        scaleShowVerticalLines: false,
        responsive: true,
        AnimationEffect: true,
        scales: {
            xAxes: [{
                ticks: {
                    autoSkip: false,
                    stepSize: 1,
                    min: 0
                }
        }]
    }
  };
  public lineChart2Options: any = {
    scaleShowVerticalLines: false,
    responsive: true,
    AnimationEffect: true,
    scales: {
        xAxes: [{
            ticks: {
                autoSkip: false,
                stepSize: 1,
                min: 0
            }
    }]
}
};

  public line2ChartOptions: any = {
      scaleShowVerticalLines: false,
      responsive: true,
      AnimationEffect: true,
      scales: {
          xAxes: [{
              ticks: {
                  autoSkip: false,
                  stepSize: 1,
                  min: 0
              }
          }]
      }
  };

  public doughnutChartOptions: any = {
  responsive: true,
      showAllTooltips: true,
  indexLabelPlacement: "outside",
      legend: {
        display: true
      }
  };
  public doughnutChartRuleOptions: any = {
    responsive: true,
    AnimationEffect: true,
    showAllTooltips: true,
    indexLabelPlacement: "outside",
    legend: {
      display: true
    }
  };

    ngOnInit() {
      window.scrollTo(0, 0);
      this.resultStatus = sessionStorage.getItem('resultStatus');
      // console.log("status:" + this.resultStatus);
      if (this.resultStatus === 'NODATA') {
          this.router.navigate(['/progress']);
      }

        this.getDashboardTileDeatils();
        this.getRulesByChartDetails();
        this.getDBChartDetails();
        this.lineChartLegend = false;
        this.lineChart2Legend = false;
        this.line2ChartLegend = true;
         //second stacked bar graph
         this.dataservice.getBusinessConnectedRulesChartDetails().subscribe(res => {
          let l = 0;
          // tslint:disable-next-line:forin
          for (const key in res.businessConnectedRules) {
                  this.barChart2Labels[l] = key;
                  l++;
          }
          let m = 0, z = 0;
          for (let i = 0; i < this.barChart2Labels.length; i++)   {
                  z = 0;
                  let x = 0;
                  this.tempArr = [];
                  this.barChart2Data[m] = {};
                  this.barChart2Colors[m] = {backgroundColor: []};
                  this.barChart2Data[m].data = [];
                  this.barChart2Data[m].label = [];
                  this.barChart2Data[m].backgroundColor = [];
                  this.barChart2Colors[m].backgroundColor = [];
                  const tempArr2 = [];
                  const tempArr1 = JSON.stringify(res.businessConnectedRules[this.barChart2Labels[i]]);
                  
                  JSON.parse(tempArr1, (key, value) => {
                      if (value !== undefined && value != null && typeof value !== 'object') {
                       this.tempArr[z] = value;
                       tempArr2[z] = key;
                       this.barChart2LabelHeader[x] = key;
                       x++;
                      }
                      z++;
                  });

                  Object.keys(this.tempArr).forEach( key => {
                      this.barChart2Data[m].data.push(this.tempArr[key]);
                      
                      this.barChart2Colors[m].backgroundColor.push(this.randomColorPicker(m));
                  });
                  this.barChart2Data[m].label = this.barChart2Labels[m];
                  m++;
          }
          this.barChart2Legend = true;
          this.barChart2Type = 'bar';
        });
        // Top 10 - Application vs Tech Stack Vs LoC
        setTimeout(() => {
            const chart2 = document.getElementById('top10appvstechvsloc');

            html2canvas(chart2, {
              width: 1100,
              height: 350,
              scale: 1,
              backgroundColor: '#ffffff',
              logging: false,
              onclone: (document) => {
                document.getElementById('top10appvstechvsloc').style.visibility = 'visible';
              }
            }).then((canvas) => {
              // Get chart data so we can append to the pdf
              const chartData = canvas.toDataURL();
              // Prepare pdf structure
              const docDefTop10AppTechLoc = { content: [],
                styles: {
                  subheader: {
                    fontSize: 16,
                    bold: true,
                    margin: [0, 10, 0, 5],
                    alignment: 'left'
                  },
                  subsubheader: {
                    fontSize: 12,
                    italics: true,
                    margin: [0, 10, 0, 25],
                    alignment: 'left'
                  }
                },
                defaultStyle: {
                  alignment: 'justify'
                }
              };
              const title2 = {text: 'Top 10 - Application vs Tech Stack Vs LoC', style: 'subheader'};
              docDefTop10AppTechLoc.content.push(title2);
              docDefTop10AppTechLoc.content.push({image: chartData, width: 500});
              this.docDefTop10AppTechLoc = docDefTop10AppTechLoc;
            }, error => {
                  console.log(error);
                });
          }, 1100);
          // Orphan Component
        setTimeout(() => {
             const chart = document.getElementById('orphanchart');

             html2canvas(chart, {
              width: 500,
             height: 350,
               scale: 1,
               backgroundColor: '#ffffff',
               logging: false,
               onclone: (document) => {
                 document.getElementById('orphanchart').style.visibility = 'visible';
               }
             }).then((canvas) => {
               // Get chart data so we can append to the pdf
               const chartData = canvas.toDataURL();
               // Prepare pdf structure
               const docDefOrphan = { content: [],
                 styles: {
                   subheader: {
                     fontSize: 16,
                     bold: true,
                     margin: [0, 10, 0, 5],
                     alignment: 'left'
                   },
                   subsubheader: {
                     fontSize: 12,
                     italics: true,
                     margin: [0, 10, 0, 25],
                     alignment: 'left'
                   }
                 },
                 defaultStyle: {
                   alignment: 'justify'
                 }
               };
               const title = {text: 'Orphan Component', style: 'subheader'};
               docDefOrphan.content.push(title);
               docDefOrphan.content.push({image: chartData, width: 500});
               this.docDefOrphan = docDefOrphan;
             }, error => {
              console.log(error);
            });
           }, 1100);

             // Rules By Type
        setTimeout(() => {
          const chart = document.getElementById('orphanRulechart');

          html2canvas(chart, {
           width: 500,
          height: 350,
            scale: 1,
            backgroundColor: '#ffffff',
            logging: false,
            onclone: (document) => {
              document.getElementById('orphanRulechart').style.visibility = 'visible';
            }
          }).then((canvas) => {
            // Get chart data so we can append to the pdf
            const chartData = canvas.toDataURL();
            // Prepare pdf structure
            const docDefRules = { content: [],
              styles: {
                subheader: {
                  fontSize: 16,
                  bold: true,
                  margin: [0, 10, 0, 5],
                  alignment: 'left'
                },
                subsubheader: {
                  fontSize: 12,
                  italics: true,
                  margin: [0, 10, 0, 25],
                  alignment: 'left'
                }
              },
              defaultStyle: {
                alignment: 'justify'
              }
            };
            const title = {text: 'Rules By Type', style: 'subheader'};
            docDefRules.content.push(title);
            docDefRules.content.push({image: chartData, width: 500});
            this.docDefRules = docDefRules;
          }, error => {
            console.log(error);
          });
        }, 1100);

        // Technical Debts- Deadline
        setTimeout(() => {
            const chart1 = document.getElementById('TechDebtschart');

            html2canvas(chart1, {
             width: 500,
            height: 350,
              scale: 1,
              backgroundColor: '#ffffff',
              logging: false,
              onclone: (document) => {
                document.getElementById('TechDebtschart').style.visibility = 'visible';
              }
            }).then((canvas) => {
              // Get chart data so we can append to the pdf
              const chartData = canvas.toDataURL();
              // Prepare pdf structure
              const docDefDeadline = { content: [],
                styles: {
                  subheader: {
                    fontSize: 16,
                    bold: true,
                    margin: [0, 10, 0, 5],
                    alignment: 'left'
                  },
                  subsubheader: {
                    fontSize: 12,
                    italics: true,
                    margin: [0, 10, 0, 25],
                    alignment: 'left'
                  }
                },
                defaultStyle: {
                  alignment: 'justify'
                }
              };
              const title1 = {text: 'Technical Debts- Deadline', style: 'subheader'};
              docDefDeadline.content.push(title1);
              docDefDeadline.content.push({image: chartData, width: 500});
              this.docDefDeadline = docDefDeadline;
            }, error => {
              console.log(error);
            });
          }, 1100);

           // Tech Stack vs Component count
        setTimeout(() => {
            const chart3 = document.getElementById('TechStackvsLoCchart');

            html2canvas(chart3, {
             width: 1100,
            height: 350,
              scale: 3,
              backgroundColor: '#ffffff',
              logging: false,
              onclone: (document) => {
                document.getElementById('TechStackvsLoCchart').style.visibility = 'visible';
              }
            }).then((canvas) => {
              // Get chart data so we can append to the pdf
              const chartData = canvas.toDataURL();
              // Prepare pdf structure
              const docDefTechvsLoc = { content: [],
                styles: {
                  subheader: {
                    fontSize: 16,
                    bold: true,
                    margin: [0, 10, 0, 5],
                    alignment: 'left'
                  },
                  subsubheader: {
                    fontSize: 12,
                    italics: true,
                    margin: [0, 10, 0, 25],
                    alignment: 'left'
                  }
                },
                defaultStyle: {
                  alignment: 'justify'
                }
              };
              const title3 = {text: 'Tech Stack vs Component count', style: 'subheader'};
              docDefTechvsLoc.content.push(title3);
              docDefTechvsLoc.content.push({image: chartData, width: 500});
              this.docDefTechvsLoc = docDefTechvsLoc;
            }, error => {
              console.log(error);
            });
          }, 1100);

           // Top 5 Application vs Deadlines
        setTimeout(() => {
            const chart4 = document.getElementById('top5appvsdeadline');

            html2canvas(chart4, {
             width: 500,
            height: 350,
              scale: 3,
              backgroundColor: '#ffffff',
              logging: false,
              onclone: (document) => {
                document.getElementById('top5appvsdeadline').style.visibility = 'visible';
              }
            }).then((canvas) => {
              // Get chart data so we can append to the pdf
              const chartData = canvas.toDataURL();
              // Prepare pdf structure
              const docDefTop5TechvsDead = { content: [],
                styles: {
                  subheader: {
                    fontSize: 16,
                    bold: true,
                    margin: [0, 10, 0, 5],
                    alignment: 'left'
                  },
                  subsubheader: {
                    fontSize: 12,
                    italics: true,
                    margin: [0, 10, 0, 25],
                    alignment: 'left'
                  }
                },
                defaultStyle: {
                  alignment: 'justify'
                }
              };
              const title4 = {text: 'Top 5 Application vs Deadlines', style: 'subheader'};
              docDefTop5TechvsDead.content.push(title4);
              docDefTop5TechvsDead.content.push({image: chartData, width: 500});
              this.docDefTop5TechvsDead = docDefTop5TechvsDead;
            }, error => {
              console.log(error);
            });
          }, 1100);

          // Top 5 Application vs LoC
        setTimeout(() => {
            const chart5 = document.getElementById('top5appvsloc');

            html2canvas(chart5, {
             width: 500,
            height: 350,
              scale: 3,
              backgroundColor: '#ffffff',
              logging: false,
              onclone: (document) => {
                document.getElementById('top5appvsloc').style.visibility = 'visible';
              }
            }).then((canvas) => {
              // Get chart data so we can append to the pdf
              const chartData = canvas.toDataURL();
              // Prepare pdf structure
              const docDefTop5TechvsLoc = { content: [],
                styles: {
                  subheader: {
                    fontSize: 16,
                    bold: true,
                    margin: [0, 10, 0, 5],
                    alignment: 'left'
                  },
                  subsubheader: {
                    fontSize: 12,
                    italics: true,
                    margin: [0, 10, 0, 25],
                    alignment: 'left'
                  }
                },
                defaultStyle: {
                  alignment: 'justify'
                }
              };
              const title5 = {text: 'Top 5 Application vs Deadlines', style: 'subheader'};
              docDefTop5TechvsLoc.content.push(title5);
              docDefTop5TechvsLoc.content.push({image: chartData, width: 500});
              this.docDefTop5TechvsLoc = docDefTop5TechvsLoc;
            }, error => {
              console.log(error);
            });
          }, 1100);
        console.clear();
      }

    downloadCOrphan(chartdesc) {
      // Download PDF
      if (this.docDefOrphan) {
          pdfMake.createPdf(this.docDefOrphan).download(chartdesc + '.pdf');
      } else {
        console.log('Chart is not yet rendered!');
      }
    }
    // Rules by Type
    downloadCRules(chartdesc) {
      // Download PDF
      if (this.docDefRules) {
          pdfMake.createPdf(this.docDefRules).download(chartdesc + '.pdf');
      } else {
        console.log('Chart is not yet rendered!');
      }
    }

    downloadCDeadline(chartdesc) {
          // Download PDF
      if (this.docDefDeadline) {
          pdfMake.createPdf(this.docDefDeadline).download(chartdesc + '.pdf');
      } else {
        console.log('Chart is not yet rendered!');
      }
    }
    downloadCTop10AppTechLoc(chartdesc) {
          // Download PDF
      if (this.docDefTop10AppTechLoc) {
          pdfMake.createPdf(this.docDefTop10AppTechLoc).download(chartdesc + '.pdf');
      } else {
        console.log('Chart is not yet rendered!');
      }

    }
    downloadAppWiseRules(chartdesc) {
      // Download PDF
      if (this.docDefAppwiseRules) {
          pdfMake.createPdf(this.docDefAppwiseRules).download(chartdesc + '.pdf');
      } else {
        console.log('Chart is not yet rendered!');
      }
    }

    downloadCTechvsLoc(chartdesc) {
          // Download PDF
      if (this.docDefTechvsLoc) {
          pdfMake.createPdf(this.docDefTechvsLoc).download(chartdesc + '.pdf');
      } else {
        console.log('Chart is not yet rendered!');
      }
    }
    downloadCTop5TechvsDead(chartdesc) {
          // Download PDF
      if (this.docDefTop5TechvsDead) {
          pdfMake.createPdf(this.docDefTop5TechvsDead).download(chartdesc + '.pdf');
      } else {
        console.log('Chart is not yet rendered!');
      }
    }
    downloadCTop5TechvsLoc(chartdesc) {
          // Download PDF
      if (this.docDefTop5TechvsLoc) {
          pdfMake.createPdf(this.docDefTop5TechvsLoc).download(chartdesc + '.pdf');
      } else {
        console.log('Chart is not yet rendered!');
      }
    }
    downloadAppWiseCyclo(chartdesc) {
          // Download PDF
      if (this.docDefAppwiseCyclo) {
          pdfMake.createPdf(this.docDefAppwiseCyclo).download(chartdesc + '.pdf');
      } else {
        console.log('Chart is not yet rendered!');
      }
    }
    downloadAppWiseInOutBound(chartdesc) {
      // Download PDF
      if (this.docDefAppwiseInOutBound) {
          pdfMake.createPdf(this.docDefAppwiseInOutBound).download(chartdesc + '.pdf');
      } else {
        console.log('Chart is not yet rendered!');
      }
    }
    getDBChartDetails() {
        this.dataservice.getDBChartDetails().subscribe(res => {
          this.pieChartDs = res;
          console.clear();
          this.total_deadLine = this.pieChartDs.technical_debt.total_dead_loc + this.pieChartDs.technical_debt.total_active_loc;
          this.pieChartData[0] = Math.round((this.pieChartDs.technical_debt.total_dead_loc / this.total_deadLine) * 100);
          this.pieChartData[1] = Math.round((this.pieChartDs.technical_debt.total_active_loc / this.total_deadLine) * 100);
          this.pieChartType = 'pie';

            let l = 0;
            // tslint:disable-next-line:forin
            for (const key in this.pieChartDs.app_tech_loc) {
                    this.barChartLabels[l] = key;
                    l++;
            }
            let m = 0, z = 0;
            // var len = 0;
            // for(var c in this.pieChartDs.app_tech_loc[this.barChartLabels[0]])
            // {
            //     len = len + 1;
            // }
           // console.log(len);
            for (let i = 0; i < this.barChartLabels.length; i++)   {
                    z = 0;
                    let x = 0;
                    this.tempArr = [];
                    this.barChartData[m] = {};
                    this.barChartColors[m] = {backgroundColor: []};
                    this.barChartData[m].data = [];
                    this.barChartData[m].label = [];
                    this.barChartData[m].backgroundColor = [];
                    this.barChartColors[m].backgroundColor = [];
                    const tempArr2 = [];
                    const tempArr1 = JSON.stringify(this.pieChartDs.app_tech_loc[this.barChartLabels[i]]);
                    JSON.parse(tempArr1, (key, value) => {
                        if (value !== undefined && value != null && typeof value !== 'object') {
                         this.tempArr[z] = value;
                         tempArr2[z] = key;
                         this.barChartLabelHeader[x] = key;
                         x++;
                        }
                        z++;
                    });

                    Object.keys(this.tempArr).forEach( key => {
                        this.barChartData[m].data.push(this.tempArr[key]);
                        this.barChartColors[m].backgroundColor.push(this.randomColorPicker(m));
                    });
                    this.barChartData[m].label = this.barChartLabels[m];
                    m++;
            }
            this.barChartLegend = true;
            this.barChartType = 'bar';
            this.pieChartDs = res;
            let k = 0;
            // tslint:disable-next-line:forin
            for (const key in this.pieChartDs.techstack_vs_component_count) {
                this.horizontalChartLabels[k] = key;
                k++;
            }

            for (let i = 0; i < k; i++) {
                this.chartDatasets[0].data[i] = this.pieChartDs.techstack_vs_component_count[this.horizontalChartLabels[i]];
            }
            let toFindMaxArr = this.chartDatasets[0].data;
            var largest= 0;
            for (var i=0; i<=largest;i++){
                if (toFindMaxArr[i]>largest) {
                  largest=toFindMaxArr[i];
                }
            }
            this.chartType = 'horizontalBar';
            this.chartOptions.scales.xAxes[0]['ticks'].suggestedMax = largest + 2;

            this.total = this.pieChartDs.orphan_stats.orphan_components + this.pieChartDs.orphan_stats.active_components;
            this.doughnutChartData[0] = Math.round((this.pieChartDs.orphan_stats.orphan_components / this.total) * 100);
            this.doughnutChartData[1] = Math.round((this.pieChartDs.orphan_stats.active_components / this.total) * 100);
            this.doughnutChartType = 'doughnut';

            //rules by chart cut
            /*let c = 0;
            let tot_rule = 0;
            // tslint:disable-next-line:forin
            for (const key in res.rules_distribution) {
                    this.doughnutChartRuleLabels[c] = key;
                    this.doughnutChartRuleData[c] = res.rules_distribution[key];
                    tot_rule = tot_rule + this.doughnutChartRuleData[c];
                    c++;
            }
            this.doughnutChartRuleType = 'doughnut';
            // for(let kk=0; kk < c; kk++)
            // {
            //       tot_rule = tot_rule + this.doughnutChartRuleData[kk];

            // }
            (document.getElementById('lblTotRule') as HTMLInputElement).innerText = 'Total no. of Rules: ' + tot_rule;*/


            this.getAppVsDeadLineData(this.pieChartDs.largest_applications_dead_code);
            this.lineChartType = 'line';

            this.getLineData(this.pieChartDs.largest_applications);
            this.line2ChartType = 'polarArea';

            //second line graph
            this.dataservice.getCyclomaticChartDetails().subscribe(res => {
              
              this.getCyclomaticData(res.cyclomatic_complexity);
              this.lineChart2Type = 'line';
              
              setTimeout(() => {
                const chart8 = document.getElementById('appwisecyclo');
        
                html2canvas(chart8, {
                 width: 500,
                 height: 350,
                  scale: 3,
                  backgroundColor: '#ffffff',
                  logging: false,
                  onclone: (document) => {
                    document.getElementById('appwisecyclo').style.visibility = 'visible';
                  }
                }).then((canvas) => {
                  // Get chart data so we can append to the pdf
                  const chartData = canvas.toDataURL();
                  // Prepare pdf structure
                  const docDefAppwiseCyclo = { content: [],
                    styles: {
                      subheader: {
                        fontSize: 16,
                        bold: true,
                        margin: [0, 10, 0, 5],
                        alignment: 'left'
                      },
                      subsubheader: {
                        fontSize: 12,
                        italics: true,
                        margin: [0, 10, 0, 25],
                        alignment: 'left'
                      }
                    },
                    defaultStyle: {
                      alignment: 'justify'
                    }
                  };
                  const title8 = {text: 'Application wise Cyclomatic Complexity', style: 'subheader'};
                  docDefAppwiseCyclo.content.push(title8);
                  docDefAppwiseCyclo.content.push({image: chartData, width: 500});
                  this.docDefAppwiseCyclo = docDefAppwiseCyclo;
                }, error => {
                  console.log(error);
                });
              }, 1100);
            });

           

            setTimeout(() => {
              const chart9 = document.getElementById('appwiseRules');
  
              html2canvas(chart9, {
                width: 1100,
                height: 350,
                scale: 1,
                backgroundColor: '#ffffff',
                logging: false,
                onclone: (document) => {
                  document.getElementById('appwiseRules').style.visibility = 'visible';
                }
              }).then((canvas) => {
                // Get chart data so we can append to the pdf
                const chartData = canvas.toDataURL();
                // Prepare pdf structure
                const docDefAppwiseRules = { content: [],
                  styles: {
                    subheader: {
                      fontSize: 16,
                      bold: true,
                      margin: [0, 10, 0, 5],
                      alignment: 'left'
                    },
                    subsubheader: {
                      fontSize: 12,
                      italics: true,
                      margin: [0, 10, 0, 25],
                      alignment: 'left'
                    }
                  },
                  defaultStyle: {
                    alignment: 'justify'
                  }
                };
                const title9 = {text: 'Application wise Rules', style: 'subheader'};
                docDefAppwiseRules.content.push(title9);
                docDefAppwiseRules.content.push({image: chartData, width: 500});
                this.docDefAppwiseRules = docDefAppwiseRules;
              }, error => {
                    console.log(error);
                  });
            }, 1100);
           //// console.log(this.pieChartDs);

           this.dataservice.getInboundOutBoundChartDetails().subscribe(res => {
            let l = 0;
            // tslint:disable-next-line:forin
            for (const key in res.inboundOutbound) {
                    this.barChart3Labels[l] = key;
                    l++;
            }
            let m = 0, z = 0;
            for (let i = 0; i < this.barChart3Labels.length; i++)   {
                    z = 0;
                    let x = 0;
                    this.tempArr = [];
                    this.barChart3Data[m] = {};
                    this.barChart3Colors[m] = {backgroundColor: []};
                    this.barChart3Data[m].data = [];
                    this.barChart3Data[m].label = [];
                    this.barChart3Data[m].backgroundColor = [];
                    this.barChart3Colors[m].backgroundColor = [];
                    const tempArr2 = [];
                    const tempArr1 = JSON.stringify(res.inboundOutbound[this.barChart3Labels[i]]);
                    JSON.parse(tempArr1, (key, value) => {
                        if (value !== undefined && value != null && typeof value !== 'object') {
                         this.tempArr[z] = value;
                         tempArr2[z] = key;
                         this.barChart3LabelHeader[x] = key;
                         x++;
                        }
                        z++;
                    });

                    Object.keys(this.tempArr).forEach( key => {
                        this.barChart3Data[m].data.push(this.tempArr[key]);
                        this.barChart3Colors[m].backgroundColor.push(this.randomColorPicker(m));
                    });
                    this.barChart3Data[m].label = this.barChart3Labels[m];
                    m++;
            }
            this.barChart3Legend = true;
            this.barChart3Type = 'bar';
          });

          setTimeout(() => {
            const chart10 = document.getElementById('appwiseInOutBound');

            html2canvas(chart10, {
              width: 1100,
              height: 350,
              scale: 1,
              backgroundColor: '#ffffff',
              logging: false,
              onclone: (document) => {
                document.getElementById('appwiseInOutBound').style.visibility = 'visible';
              }
            }).then((canvas) => {
              // Get chart data so we can append to the pdf
              const chartData = canvas.toDataURL();
              // Prepare pdf structure
              const docDefAppwiseInOutBound = { content: [],
                styles: {
                  subheader: {
                    fontSize: 16,
                    bold: true,
                    margin: [0, 10, 0, 5],
                    alignment: 'left'
                  },
                  subsubheader: {
                    fontSize: 12,
                    italics: true,
                    margin: [0, 10, 0, 25],
                    alignment: 'left'
                  }
                },
                defaultStyle: {
                  alignment: 'justify'
                }
              };
              const title10 = {text: 'Application wise Inbound & Outbound', style: 'subheader'};
              docDefAppwiseInOutBound.content.push(title10);
              docDefAppwiseInOutBound.content.push({image: chartData, width: 500});
              this.docDefAppwiseInOutBound = docDefAppwiseInOutBound;
            }, error => {
                  console.log(error);
                });
          }, 1100);

          }, error => {
            console.log(error);
          });
    }
    getRulesByChartDetails(){
        // Rules By type
        this.dataservice.getRulesByChartDetails().subscribe(res => {
          let c = 0;
          let tot_rule = 0;
          // tslint:disable-next-line:forin
          for (const key in res.rules_distribution) {
                  this.doughnutChartRuleLabels[c] = key;
                  this.doughnutChartRuleData[c] = res.rules_distribution[key];
                  tot_rule = tot_rule + this.doughnutChartRuleData[c];
                  c++;
          }
          this.doughnutChartRuleType = 'doughnut';
          // for(let kk=0; kk < c; kk++)
          // {
          //       tot_rule = tot_rule + this.doughnutChartRuleData[kk];
          // }
          (document.getElementById('lblTotRule') as HTMLInputElement).innerText = 'Total no. of Rules: ' + tot_rule;
        // console.log("Total: " + tot_rule);
        });
    }
    getAppVsDeadLineData(temp: any[]) {
        temp.forEach(element => {
            this.lineChartData[0].data.push(element.no_of_dead_lines);
            this.lineChartLabels.push(element.application_name);
        });
    }
    getLineData(temp: any[]) {
        temp.forEach(element => {
            this.line2ChartData[0].data.push(element.loc);
            this.line2ChartLabels.push(element.application_name);
        });
    }
    getCyclomaticData(temp: any[]) {
      temp.forEach(element => {
          this.lineChart2Data[0].data.push(element.cyclomatic_complexity);
          this.lineChart2Labels.push(element.application_name);
      });
    }
    public randomize(): void {
        // Only Change 3 values
        const data = [
            Math.round(Math.random() * 100),
            59,
            80,
            Math.random() * 100,
            56,
            Math.random() * 100,
            40
        ];
        const clone = JSON.parse(JSON.stringify(this.barChartData));
        clone[0].data = data;
        this.barChartData = clone;
        /**
         * (My guess), for Angular to recognize the change in the dataset
         * it has to change the dataset variable directly,
         * so one way around it, is to clone the data, change it and then
         * assign it;
         */
    }
    getDashboardTileDeatils() {
        this.dataservice.getDashboardTileDeatils().subscribe(res => {
            this.dataSets = res;
            console.clear();
          }, error => {
            console.log(error);
          });
    }


   randomColorPicker(temp: any) {
        if (this.map.get(temp) != null) {
            return this.map.get(temp);
        } else {
            const color = 'rgba(' + Math.floor(Math.random() * 255) + ',' +
              Math.floor(Math.random() * 100) + ',' + Math.floor(Math.random() * 200) + ')';
            this.map.set(temp, color);
            return color;
        }
   }
  //  getDetails(){
  //   this.dataservice.getChartDetails().subscribe(res => {
  //     console.log(res['Connected Buisiness Rule']);
  //     console.log(res['Connected Buisiness Rule']['GENERAL LEDGER']);
  //   });
  // }

    public closeAlert(alert: any) {
        const index: number = this.alerts.indexOf(alert);
        this.alerts.splice(index, 1);
        this.doughnutChartType = 'doughnut';
    }

    domtoImage(id, name) {
      const node = document.getElementById(id);
      domtoimage.toPng(node).then(function (dataUrl) {
         const img = new Image();
          img.src = dataUrl;
          const link = document.createElement('a');
          link.setAttribute('href', img.src);
          link.setAttribute('download', name);
          link.click();
      }).catch(function (error) {
          console.error('oops, something went wrong!', error);
      });
    }

     // events
    public chartClicked(e: any): void {
        // console.log(e);
    }

    public chartHovered(e: any): void {
        // console.log(e);
    }

}
