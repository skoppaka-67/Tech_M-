// import { NgModule } from '@angular/core';
import { NgModule, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';

import { CommonModule } from '@angular/common';


import {DataTablesModule } from 'angular-datatables';

import { CicsRulesAppRoutingModule } from './cicsrules-application-routing.module';
import { CicsRulesAppComponent } from './cicsrules-application.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';

import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';



@NgModule({
    imports: [CommonModule, CicsRulesAppRoutingModule, PageHeaderModule, DataTablesModule, NgxGraphModule, NgxChartsModule,
        NgbModule],
    declarations: [CicsRulesAppComponent],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [ExcelService],
    bootstrap:    [CicsRulesAppComponent]
})
export class CicsRulesAppModule {}
