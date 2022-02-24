// import { NgModule } from '@angular/core';
import { NgModule, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';

import { CommonModule } from '@angular/common';


import {DataTablesModule } from 'angular-datatables';

import { CicsRulesRoutingModule } from './cicsrules-routing.module';
import { CicsRulesComponent } from './cicsrules.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';

import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';



@NgModule({
    imports: [CommonModule, CicsRulesRoutingModule, PageHeaderModule, DataTablesModule, NgxGraphModule, NgxChartsModule,
        NgbModule],
    declarations: [CicsRulesComponent],
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    providers: [ExcelService],
    bootstrap:    [CicsRulesComponent]
})
export class CicsRulesModule {}
