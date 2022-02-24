import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { CicsScreenNatRoutingModule } from './cicsscreen-routing.module';
import { CicsScreenNatComponent } from './cicsscreen.component';
import { PageHeaderModule } from '../../shared';
import { ExcelService } from '../../excel.service';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, CicsScreenNatRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [CicsScreenNatComponent],
    providers: [ExcelService]
})
export class CicsScreenNatModule {}
