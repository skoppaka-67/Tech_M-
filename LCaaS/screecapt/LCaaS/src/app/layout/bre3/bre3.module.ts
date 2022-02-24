import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { Bre3RoutingModule } from './bre3-routing.module';
import { Bre3Component } from './bre3.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
    imports: [CommonModule, Bre3RoutingModule, PageHeaderModule, DataTablesModule, NgbModule],
    declarations: [Bre3Component]
})
export class Bre3Module {}
