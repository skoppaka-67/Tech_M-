import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { XrefRoutingModule } from './x-ref-routing.module';
import { XrefComponent } from './x-ref.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, XrefRoutingModule, PageHeaderModule, DataTablesModule, NgbModule],
    declarations: [XrefComponent]
})
export class XrefModule {}
