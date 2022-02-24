import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { ProgressRoutingModule } from './progress-routing.module';
import { ProgressComponent } from './progress.component';
import { PageHeaderModule } from '../../shared';
import { FormsModule } from '@angular/forms';
import { NgProgressModule } from '@ngx-progressbar/core';
import { NgProgressHttpClientModule } from '@ngx-progressbar/http-client';

@NgModule({
    imports: [CommonModule, ProgressRoutingModule, PageHeaderModule,DataTablesModule, FormsModule,NgProgressModule.forRoot(),NgProgressHttpClientModule], 
    declarations: [ProgressComponent]
})
export class ProgressModule {}
