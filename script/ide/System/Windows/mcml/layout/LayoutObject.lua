--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
local LayoutObject = commonlib.gettable("System.Windows.mcml.layout.LayoutObject");
LayoutObject:new():init();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutInline.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
local IntRect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local LayoutBlock = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock");
local LayoutInline = commonlib.gettable("System.Windows.mcml.layout.LayoutInline");

local LayoutRect = IntRect;

local LayoutObject = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutObject"));

function LayoutObject:ctor()
	self.name = "LayoutObject";
	self.node = nil;
	self.style = nil;
	--self.control = nil;

	self.parent = nil;
	self.previous = nil;
	self.next= nil;

	--self.children = {};

	self.setNeedsLayoutForbidden = false;

	-- LayoutObject Bit fields holds all the boolean values for LayoutObject.
	self.needsLayout = false;
	self.needsPositionedMovementLayout = false;
	self.normalChildNeedsLayout = false;
	self.posChildNeedsLayout = false;
	self.needsSimplifiedNormalFlowLayout = false;
    self.preferredLogicalWidthsDirty = false;

	self.floating = false;

	self.positioned = false;
	self.relPositioned = false;

	self.isAnonymous = false;
	
	self.isText = false;
	self.isBox = false;
	self.inline = true;
	self.replaced= false;
	self.horizontalWritingMode = true;
	self.isDragging = false;

	self.hasLayer = false;
	self.hasOverflowClip = false;
	self.hasTransform = false;
	self.hasReflection = false;

	self.everHadLayout = false;

	self.childrenInline = false;

	self.marginBeforeQuirk = false;
	self.marginAfterQuirk = false;
	self.hasMarkupTruncation = false;
--	enum SelectionState {
--        SelectionNone, // The object is not selected.
--        SelectionStart, // The object either contains the start of a selection run or is the start of a run
--        SelectionInside, // The object is fully encompassed by a selection run
--        SelectionEnd, // The object either contains the end of a selection run or is the end of a run
--        SelectionBoth // The object contains an entire run or is the sole selected object in that run
--    };
	self.selectionState = "SelectionNone";
	self.hasColumns = false;
	self.inRenderFlowThread = false;


--	self.needsUpdateCss = true;
--
--	self.bUseSpace = false;
end

function LayoutObject:init(node)
	self.node = node;
	--self.control = node:GetControl();
--	self.style = computed_style;
--	if(self.style) then
--		self.style:Connect("Changed", function()
--			self:invalidate();
--			--self.needsLayout = true;
--		end)
--	end
	return self;
end

-- 后面需要完善，暂时不调用该函数
function LayoutObject.CreateLayoutObject(node, style)
	local display = style:Display();
	if(display == "BLOCK" or display == "INLINE_BLOCK") then
		return LayoutBlock:new():init(node);
	elseif(display == "INLINE") then
		return LayoutInline:new():init(node);
	end
end

function LayoutObject:SetStyle(style)
	self.style = style;
	if(self.style) then
		self.style:Connect("Changed", function()
			self:invalidate();
			--self.needsLayout = true;
		end)
	end

	self:StyleDidChange();
end

function LayoutObject:GetControl()
	if(self.node) then
		return self.node:GetControl();
	end	
end

function LayoutObject:PreviousSibling()
	return self.previous;
end

function LayoutObject:NextSibling()
	return self.next;
end

function LayoutObject:SetPreviousSibling(previous)
	self.previous = previous;
--	if(previous) then
--		previous:SetNextSibling(self);
--	end
end

function LayoutObject:SetNextSibling(next)
	self.next = next;
end

function LayoutObject:SetParent(parent)
    self.parent = parent;
    if (parent and parent:InRenderFlowThread()) then
        self:SetInRenderFlowThread(true);
    elseif (not parent and self:InRenderFlowThread()) then
        self:SetInRenderFlowThread(false);
	end
end

function LayoutObject:AddChild(newChild, beforeChild)
	local children = self:VirtualChildren();
    if (not children) then
        return;
	end
    local beforeContent = 0;
    local beforeChildHasBeforeAndAfterContent = false;
    if (beforeChild and (beforeChild:IsTable() or beforeChild:IsTableSection() or beforeChild:IsTableRow() or beforeChild:IsTableCell())) then
--        beforeContent = beforeChild->findBeforeContentRenderer();
--        RenderObject* afterContent = beforeChild->findAfterContentRenderer();
--        if (beforeContent && afterContent) {
--            beforeChildHasBeforeAndAfterContent = true;
--            beforeContent->destroy();
--        }
    end

    local needsTable = false;

    if (newChild:IsTableCol() and newChild:Style():Display() == "TABLE_COLUMN_GROUP") then
        needsTable = not self:IsTable();
    elseif (newChild:IsLayoutBlock() and newChild:Style():Display() == "TABLE_CAPTION") then
        needsTable = not self:IsTable();
    elseif (newChild:IsTableSection()) then
        needsTable = not self:IsTable();
    elseif (newChild:IsTableRow()) then
        needsTable = not self:IsTableSection();
    elseif (newChild:IsTableCell()) then
        needsTable = not self:IsTableRow();
        -- I'm not 100% sure this is the best way to fix this, but without this
        -- change we recurse infinitely when trying to render the CSS2 test page:
        -- http://www.bath.ac.uk/%7Epy8ieh/internet/eviltests/htmlbodyheadrendering2.html.
        -- See Radar 2925291.
        if (needsTable and self:IsTableCell() and not children:FirstChild() and not newChild:IsTableCell()) then
            needsTable = false;
		end
    end

    if (needsTable) then
--        RenderTable* table;
--        RenderObject* afterChild = beforeChild ? beforeChild->previousSibling() : children->lastChild();
--        if (afterChild && afterChild->isAnonymous() && afterChild->isTable() && !afterChild->isBeforeContent())
--            table = toRenderTable(afterChild);
--        else {
--            table = new (renderArena()) RenderTable(document() /* is anonymous */);
--            RefPtr<RenderStyle> newStyle = RenderStyle::create();
--            newStyle->inheritFrom(style());
--            newStyle->setDisplay(TABLE);
--            table->setStyle(newStyle.release());
--            addChild(table, beforeChild);
--        }
--        table->addChild(newChild);
    else
        -- Just add it...
		children:InsertChildNode(self, newChild, beforeChild);
    end

--    if (newChild->isText() && newChild->style()->textTransform() == CAPITALIZE) {
--        RefPtr<StringImpl> textToTransform = toRenderText(newChild)->originalText();
--        if (textToTransform)
--            toRenderText(newChild)->setText(textToTransform.release(), true);
--    }
--
--    if (beforeChildHasBeforeAndAfterContent)
--        children->updateBeforeAfterContent(this, BEFORE);
end

function LayoutObject:AddChildIgnoringContinuation(newChild, beforeChild)
	return self:AddChild(newChild, beforeChild);
end

function LayoutObject:FirstChild()
	local children = self:VirtualChildren();
	if (children) then
        return children:FirstChild();
	end
    return nil;

--	if(next(self.children)) then
--		return self.children[1];
--	end
--	return;
end

function LayoutObject:LastChild()
	local children = self:VirtualChildren();
	if (children) then
        return children:LastChild();
	end
    return nil;
end

function LayoutObject:isHidden()
	return self.node:isHidden();
end

function LayoutObject:BeChanged()
	return self.style:BeChanged();
end

--function LayoutObject:CheckStyleChange()
--	if(not self:BeChanged()) then
--		return;
--	end
--
--	self:UpdateLayoutIfNeeded();
----	if(self:layoutChanged()) then
----		self:recalcLayout();
----	end
--
--	--self.node:up
--
--	self.style:ClearChanges();
--end

--function LayoutObject:fixedSize()
--	local style_item = self.style:GetStyle();
--	if(style_item.width and style_item.height) then
--		return true;
--	end
--	return false;
--end

--function LayoutObject:AncestorOf(layout)
--	
--end

--function LayoutObject:recalcLayout()
--	self.layout:SetUsedSize(0,0);
--	self.node:UpdateChildLayout(self.layout);
--end

--function LayoutObject:UpdateChildLayout(layout, child)
--	child:UpdateLayoutIfNeeded(layout);
--end

function LayoutObject:UpdateChildrenLayout(layout, beParentRelayout, beInDirtyRegion)
	local child = self:FirstChild();
	while(child) do
		child:UpdateLayout(layout, beParentRelayout, beInDirtyRegion);
		child = child:NextSibling();
	end
end

--function LayoutObject:beUseSpace()
--	if(self:Style():Position() == "StaticPosition") then
--		return true;
--	end
--	return false;
--end

function LayoutObject:invalidate()
	if(self.needsLayout) then
		return;
	end
	--self.needsLayout = true;
	local page_layout = self:GetPageLayout();
	page_layout:invalidate(self);
end

function LayoutObject:BeLayoutView()
	return false;
end

---- TODO: 回溯父对象，添加相应布局标志
--function LayoutObject:markContainingBlocksForLayout()
--	if(not self:beUseSpace()) then
--		return;		
--	end
--	local parent = self:GetParent();
--	while(parent) do
--		parent.childrenNeedsLayout = true;
--		--parent.needsLayout = true;
--		if(parent:beFixedLayout()) then
--			--parent.childrenNeedsLayout = true;
--			parent.beSubtreeRoot = true;
--			break;
--		end
--		local next = parent:NextSibling();
--		while(next) do
--			next.needsPositionedMovementLayout = true;
--			next = next:NextSibling();
--		end
--		parent = parent:GetParent();
--	end
--end

function LayoutObject:ChangedBackTrace()
	local changeType = self:Style():Diff();
	if(changeType ~= "no_change") then
		self.needsLayout = true;
		self.normalChildNeedsLayout = true;
		self.posChildNeedsLayout = true;
		self:markContainingBlocksForLayout();
	end

	self:Style():ClearChanges();
end

function LayoutObject:GetPageLayout()
	if(self.page_layout) then
		return self.page_layout;
	end
	return self.parent:GetPageLayout()
end

--function LayoutObject:SelfNeedsLayout()
--	return self.needsLayout;
--end

--function LayoutObject:ChildrenNeedsLayout()
--	return self.childrenNeedsLayout;
--end

function LayoutObject:BeSubtreeRoot()
	return self.beSubtreeRoot
end

--function LayoutObject:NeedsUpdateCSS()
--	if(self.needsUpdateCss) then 
--		return true;
--	end
--	return false;
--end

function LayoutObject:UpdateCssStyle()
	self.needsUpdateCss = false;
	local control = self:GetControl();
	if(control) then
		control:ApplyCss(self:Style():GetStyle());
	end
end

function LayoutObject:UpdateLayoutIfNeeded(layout, beParentRelayout, beInDirtyRegion)
--	if(self:NeedsLayout() or beParentRelayout) then
--		self:UpdateLayout(layout, beParentRelayout);
--	else
----		local child = self:FirstChild();
----		while(child) do
----			self:UpdateChildLayout(nil, child);
----			child = child:NextSibling();
----		end
--		self:UpdateChildrenLayout();
--	end

	--self:UpdateChildrenLayout(layout);
end

function LayoutObject:CanHaveChildren()
	return true;
end

function LayoutObject:IsChildAllowed(child_layout_object, child_style)
	return true;
end

function LayoutObject:IsAbsolutePositioned()
	if(self:Style():Position() == "AbsolutePosition") then
		return true;
	end
	return false;
end

function LayoutObject:IsRelativePositioned()
	if(self:Style():Position() == "RelativePosition") then
		return true;
	end
	return false;
end

-------------------------------------------------------------
-- virtual methods
-------------------------------------------------------------
function LayoutObject:UpdateLayout(layout,beParentRelayout, beInDirtyRegion)
	self:UpdateChildrenLayout(layout,beParentRelayout, beInDirtyRegion);

	if(self:NeedsUpdateCSS()) then
		self:UpdateCssStyle();
	end

	self.needsLayout = false;
	self.childrenNeedsLayout = false;
end


function LayoutObject:CreateLayout(child_index)
	
end

---------------------------------------------------------------------------------------------------
----------------	webkit/chromium	function
function LayoutObject:IsApplet()
	return false;
end
function LayoutObject:IsBR()
	return false;
end
function LayoutObject:IsBlockFlow()
	return false;
end
function LayoutObject:IsBoxModelObject()
	return false;
end
function LayoutObject:IsCounter()
	return false;
end
function LayoutObject:IsQuote()
	return false;
end
function LayoutObject:IsEmbeddedObject()
	return false;
end
function LayoutObject:IsFieldset()
	return false;
end
function LayoutObject:IsFileUploadControl()
	return false;
end
function LayoutObject:IsFrame()
	return false;
end
function LayoutObject:IsFrameSet()
	return false;
end
function LayoutObject:IsImage()
	return false;
end
function LayoutObject:IsInlineBlockOrInlineTable()
	return false;
end
function LayoutObject:IsListBox()
	return false;
end
function LayoutObject:IsListItem()
	return false;
end
function LayoutObject:IsListMarker()
	return false;
end
function LayoutObject:IsMedia()
	return false;
end
function LayoutObject:IsMenuList()
	return false;
end
function LayoutObject:IsMeter()
	return false;
end
function LayoutObject:IsProgress()
	return false;
end
function LayoutObject:IsLayoutBlock()
	return false;
end
function LayoutObject:IsLayoutButton()
	return false;
end
function LayoutObject:IsLayoutIFrame()
	return false;
end
function LayoutObject:IsLayoutImage()
	return false;
end
function LayoutObject:IsLayoutInline()
	return false;
end
function LayoutObject:IsLayoutPart()
	return false;
end
function LayoutObject:IsLayoutRegion()
	return false;
end
function LayoutObject:IsLayoutView()
	return false;
end
function LayoutObject:IsReplica()
	return false;
end
function LayoutObject:IsRuby()
	return false;
end
function LayoutObject:IsRubyBase()
	return false;
end
function LayoutObject:IsRubyRun()
	return false;
end
function LayoutObject:IsRubyText()
	return false;
end
function LayoutObject:IsSlider()
	return false;
end
function LayoutObject:IsSliderThumb()
	return false;
end
function LayoutObject:IsSummary()
	return false;
end
function LayoutObject:IsTable()
	return false;
end
function LayoutObject:IsTableCell()
	return false;
end
function LayoutObject:IsTableCol()
	return false;
end
function LayoutObject:IsTableRow()
	return false;
end
function LayoutObject:IsTableSection()
	return false;
end
function LayoutObject:IsTextControl()
	return false;
end
function LayoutObject:IsTextArea()
	return false;
end
function LayoutObject:IsTextField()
	return false;
end
function LayoutObject:IsVideo()
	return false;
end
function LayoutObject:IsWidget()
	return false;
end
function LayoutObject:IsCanvas()
	return false;
end
function LayoutObject:IsLayoutFullScreen()
	return false;
end
function LayoutObject:IsLayoutFullScreenPlaceholder()
	return false;
end
function LayoutObject:IsLayoutFlowThread()
	return false;
end

function LayoutObject:SetChildNeedsLayout(bChildrenNeedLayout, bMarkParents)
	local alreadyNeededLayout = self.normalChildNeedsLayout;
    self.normalChildNeedsLayout = bChildrenNeedLayout;
    if (bChildrenNeedLayout) then
        if (not alreadyNeededLayout and bMarkParents) then
            self:MarkContainingBlocksForLayout();
		end
    else
        self.posChildNeedsLayout = false;
        self.needsSimplifiedNormalFlowLayout = false;
        self.normalChildNeedsLayout = false;
        self.needsPositionedMovementLayout = false;
    end
end

function LayoutObject:IsAnonymous()
	return self.isAnonymous;
end

function LayoutObject:SetIsAnonymous(isAnonymous)
	self.isAnonymous = isAnonymous;
end

function LayoutObject:IsAnonymousBlock()
	return self.isAnonymous and (self:Style():Display() == "BLOCK" or self:Style():Display() == "BOX") and self:Style():StyleType() == "NOPSEUDO" and self:IsLayoutBlock() and self:IsListMarker();
end

function LayoutObject:IsAnonymousColumnsBlock()
	return self:Style():SpecifiesColumns() and self:IsAnonymousBlock();
end

function LayoutObject:IsAnonymousColumnSpanBlock()
	return self:Style():ColumnSpan() and self:IsAnonymousBlock();
end

function LayoutObject:IsElementContinuation()
	return self:Node() ~= nil and self:Node():Renderer() ~= self;
end

function LayoutObject:IsInlineElementContinuation()
	return self:IsElementContinuation() and self:IsInline();
end

function LayoutObject:IsBlockElementContinuation()
	return self:IsElementContinuation() and not self:IsInline();
end

function LayoutObject:IsRenderFlowThread()
	return false;
end

function LayoutObject:IsText()
	return self.isText;
end

function LayoutObject:IsBox()
	return self.isBox;
end

function LayoutObject:IsInline()
	return self.inline;
end

function LayoutObject:IsFloating()
	return self.floating;
end
-- absolute or fixed positioning
function LayoutObject:IsPositioned()
	return self.positioned;
end

-- absolute or fixed positioning
function LayoutObject:IsRelPositioned()
	return self.relPositioned;
end

function LayoutObject:IsReplaced()
	return self.replaced;
end

function LayoutObject:IsHorizontalWritingMode()
	return self.horizontalWritingMode;
end

function LayoutObject:HasLayer()
	return self.hasLayer;
end

function LayoutObject:IsRoot()
	--TODO: fixed this function
	return false;
end

function LayoutObject:IsBody()
	return self.node.name == "body";
end

function LayoutObject:IsHR()
	return self.node.name == "hr";
end

function LayoutObject:IsLegend()
	return self.node.name == "legend";
end

function LayoutObject:IsHTMLMarquee()
	return self.node.name == "marquee";
end

--@param obj: LayoutObject type
--@param beSelf: check self;
function LayoutObject:IsBeforeContent(obj, beSelf)
	beSelf = if_else(beSelf == nil, true, beSelf);
	if(not beSelf) then
		return obj ~= nil and obj:IsBeforeContent();
	end

	if (self:Style():StyleType() ~= "BEFORE") then
		return false;
	end
	-- Text nodes don't have their own styles, so ignore the style on a text node.
	if (self:IsText() and not self:IsBR()) then
		return false;
	end
	return true;
end

--@param obj: LayoutObject type
function LayoutObject:IsAfterContent(obj, beSelf)
	beSelf = if_else(beSelf == nil, true, beSelf);
	if(not beSelf) then
		return obj ~= nil and obj:IsAfterContent();
	end
	if (self:Style():StyleType() ~= "AFTER") then
        return false;
	end
    -- Text nodes don't have their own styles, so ignore the style on a text node.
    if (self:IsText() and not self:IsBR()) then
        return false;
	end
    return true;
end

--@param obj: LayoutObject type
function LayoutObject.IsBeforeOrAfterContent(obj, beSelf)
	beSelf = if_else(beSelf == nil, true, beSelf);
	if(not beSelf) then
		return obj ~= nil and obj:IsBeforeOrAfterContent();
	end

	return self:IsBeforeContent() or self:IsAfterContent();
end

function LayoutObject:FindBeforeContentRenderer()
--    local renderer = beforePseudoElementRenderer();
--    return isBeforeContent(renderer) ? renderer : 0;
end

function LayoutObject:FindAfterContentRenderer()
    local renderer = self:AfterPseudoElementRenderer();
	if(LayoutObject:IsAfterContent(renderer, false)) then
		return render;
	end
    return nil;
end

function LayoutObject:HasReflection()
	return self.hasReflection;
end

--function LayoutObject:AnonymousContainer(RenderObject* child)
--        RenderObject* container = child;
--        while (container->parent() != this)
--            container = container->parent();
--
--        ASSERT(container->isAnonymous());
--        return container;
--end

function LayoutObject:SetPositioned(value)
	if(value == nil) then
		value = true;
	end
	self.positioned = value;
end

function LayoutObject:SetRelPositioned(value)
	if(value == nil) then
		value = true;
	end
	self.relPositioned = value;
end

function LayoutObject:SetFloating(value)
	if(value == nil) then
		value = true;
	end
	self.floating = value;
end

function LayoutObject:SetInline(value)
	if(value == nil) then
		value = true;
	end
	self.inline = value;
end

function LayoutObject:SetIsText(value)
	if(value == nil) then
		value = true;
	end
	self.isText = value;
end

function LayoutObject:SetIsBox(value)
	if(value == nil) then
		value = true;
	end
	self.isBox = value;
end

function LayoutObject:SetIsReplace(value)
	if(value == nil) then
		value = true;
	end
	self.replaced = value;
end

function LayoutObject:SetHorizontalWritingMode(value)
	if(value == nil) then
		value = true;
	end
	self.horizontalWritingMode = value;
end

function LayoutObject:SetHasOverflowClip(value)
	if(value == nil) then
		value = true;
	end
	self.hasOverflowClip = value;
end

function LayoutObject:SetHasLayer(value)
	if(value == nil) then
		value = true;
	end
	self.hasLayer = value;
end

function LayoutObject:SetHasTransform(value)
	if(value == nil) then
		value = true;
	end
	self.hasTransform = value;
end

function LayoutObject:SetHasReflection(value)
	if(value == nil) then
		value = true;
	end
	self.hasReflection = value;
end

function LayoutObject:LayoutIfNeeded()
	if(self:NeedsLayout()) then 
		self:Layout();
	end
end

function LayoutObject:Layout()
	if(self:NeedsLayout()) then 
		local child = FirstChild();
		while (child) do
			child:LayoutIfNeeded();
			child = child:NextSibling();
		end
		SetNeedsLayout(false);
	end
end

--RenderObject* RenderObject::container(RenderBoxModelObject* repaintContainer, bool* repaintContainerSkipped) const
function LayoutObject:Container(repaintContainer, repaintContainerSkipped)
--	if (repaintContainerSkipped)
--        *repaintContainerSkipped = false;
	repaintContainerSkipped = if_else(repaintContainerSkipped == nil, false, repaintContainerSkipped);

	local object = self:Parent();

	if(self:IsText()) then
		return object;
	end

	local pos = self.style:Position();
	if(pos == "FixedPosition") then
		while (object and object:Parent() and (not (object:HasTransform() and object:IsLayoutBlock()))) do
			object = object:Parent();
		end
	elseif(pos == "AbsolutePosition") then
		while (object and object:Style():Position() == "StaticPosition" and (not object:IsLayoutView()) and (not (object:HasTransform() and object:IsLayoutBlock()))) do
			if (repaintContainerSkipped and object == repaintContainer) then
                repaintContainerSkipped = true;
			end
			object = object:Parent();
		end
	end
	return object, repaintContainerSkipped;
end

-- TODO: 回溯父对象，添加相应布局标志
-- @param scheduleRelayout:
-- @param newRoot:
function LayoutObject:MarkContainingBlocksForLayout(scheduleRelayout, newRoot)
	local object = self:Container();
	local last = self;

	local simplifiedNormalFlowLayout = self:NeedsSimplifiedNormalFlowLayout() and (not self:SelfNeedsLayout()) and (not self:NormalChildNeedsLayout());

	while(object) do
		local container = object:Container();
		-- Don't mark the outermost object of an unrooted subtree. That object will be marked when the subtree is added to the document.
		if (not container and (not object:IsLayoutView())) then
            return;
		end
		if(not last:IsText() and (last:Style():Position() == "AbsolutePosition" or last:Style():Position() == "FixedPosition") ) then
			local willSkipRelativelyPositionedInlines = not object:IsLayoutBlock();
			while (object and not object:IsLayoutBlock()) do -- Skip relatively positioned inlines and get to the enclosing RenderBlock.
                object = object:Container();
			end
			if(object and not object:IsLayoutBlock()) then
				return;
			end
			if(willSkipRelativelyPositionedInlines) then
				container = object:Container();
			end
			object.posChildNeedsLayout = true;
			simplifiedNormalFlowLayout = true;
		elseif(simplifiedNormalFlowLayout) then
			if(object.needsSimplifiedNormalFlowLayout) then
				return;
			end
			object.needsSimplifiedNormalFlowLayout = true;
		else
			if(object.normalChildNeedsLayout) then
				return;
			end
			object.normalChildNeedsLayout = true;
		end

		if(object == newRoot) then
			return;
		end

		last = object;
		object = container;
	end
end

function LayoutObject:SelfNeedsLayout()
	return self.needsLayout;
end

function LayoutObject:NeedsSimplifiedNormalFlowLayout()
	return self.needsSimplifiedNormalFlowLayout;
end

function LayoutObject:NormalChildNeedsLayout()
	return self.normalChildNeedsLayout;
end

function LayoutObject:PosChildNeedsLayout()
	return self.posChildNeedsLayout;
end

function LayoutObject:NeedsPositionedMovementLayout()
	return self.needsPositionedMovementLayout;
end

function LayoutObject:IsSetNeedsLayoutForbidden()
	return self.setNeedsLayoutForbidden;
end

function LayoutObject:PreferredLogicalWidthsDirty()
	return self.preferredLogicalWidthsDirty;
end

function LayoutObject:HasTransform()
	return self.hasTransform;
end

function LayoutObject:HasColumns()
	return self.hasColumns;
end

function LayoutObject:SetHasColumns(b)
	b = if_else(b == nil, true, b);
	self.hasColumns = b;
end

function LayoutObject:InRenderFlowThread()
	return self.inRenderFlowThread;
end

function LayoutObject:SetInRenderFlowThread(b)
	if(b == nil) then
		b = true;
	end
	self.inRenderFlowThread = b;
end

function LayoutObject:HasClip()
	return self:IsPositioned() and self:Style():HasClip();
end

function LayoutObject:HasOverflowClip()
	return self.hasOverflowClip;
end

function LayoutObject:HasMask()
	return self:Style() and self:Style():HasMask();
end

function LayoutObject:ChildrenInline()
	return self.childrenInline;
end

function LayoutObject:SetChildrenInline(value)
	self.childrenInline = value;
end

function LayoutObject:SetNeedsLayout(needsLayout, markParents)
	local alreadyNeededLayout = self.needsLayout;
	self.needsLayout = needsLayout;
	if(needsLayout) then
		if(not alreadyNeededLayout) then
			if(markParents) then
				self:MarkContainingBlocksForLayout();
			end
		end
	else
		self.everHadLayout = true;
		self.posChildNeedsLayout = false;
		self.normalChildNeedsLayout = false;
		self.needsPositionedMovementLayout = false;
		self.needsSimplifiedNormalFlowLayout = false;
	end
end

function LayoutObject:SetPreferredLogicalWidthsDirty(dirty, markParents)
	local alreadyDirty = self.preferredLogicalWidthsDirty;
    self.preferredLogicalWidthsDirty = dirty;
    if (dirty and not alreadyDirty and markParents and (self:IsText() or (self:Style():Position() ~= "FixedPosition" and self:Style():Position() ~= "AbsolutePosition"))) then
        self:InvalidateContainerPreferredLogicalWidths();
	end
end

function LayoutObject:InvalidateContainerPreferredLogicalWidths()
	local _container = self:Container();
	local object = if_else(self:IsTableCell(),self:ContainingBlock(),_container);
	while (object and not object.preferredLogicalWidthsDirty) do
        -- Don't invalidate the outermost object of an unrooted subtree. That object will be 
        -- invalidated when the subtree is added to the document.
		local container = object:Container();
        container = if_else(object:IsTableCell(),object:ContainingBlock(),container);
        if (not container and not object:IsLayoutView()) then
            break;
		end
        object.preferredLogicalWidthsDirty = true;
        if (object:Style():Position() == "FixedPosition" or object:Style():Position() == "AbsolutePosition") then
            -- A positioned object has no effect on the min/max width of its containing block ever.
            -- We can optimize this case and not go up any further.
            break;
		end
        object = container;
    end
end

function LayoutObject:NeedsLayout()
	return self.needsLayout or self.normalChildNeedsLayout or self.posChildNeedsLayout or self.needsPositionedMovementLayout or self.needsSimplifiedNormalFlowLayout;
end

function LayoutObject:FirstLineStyle()
	--return document()->usesFirstLineRules() ? firstLineStyleSlowCase() : style();
	return self.style;
end

function LayoutObject:Style(firstLine)
	if(firstLine) then
		return self:FirstLineStyle();
	else
		return self.style;
	end
end

function LayoutObject:Node()
	return if_else(self.isAnonymous, nil, self.node);
end

function LayoutObject:Parent()
	return self.parent;
end

function LayoutObject:View()
	if(self:IsLayoutView()) then
		return self;
	end
	local parent = self:Parent();
	if(parent) then
		return parent:View();
	end
end

function LayoutObject:CheckForRepaintDuringLayout()
    -- FIXME: <https://bugs.webkit.org/show_bug.cgi?id=20885> It is probably safe to also require
    -- m_everHadLayout. Currently, only RenderBlock::layoutBlock() adds this condition. See also
    -- <https://bugs.webkit.org/show_bug.cgi?id=15129>.
	local frameview = self:View():FrameView();
    return not frameview:NeedsFullRepaint() and not self:HasLayer();
end

function LayoutObject:isRooted()
    local o = self;
    while (o:Parent()) do
        o = o:Parent();
	end
    if (not o:IsLayoutView()) then
        return false;
	end
    return true, o;
end

--RenderFlowThread* RenderObject::enclosingRenderFlowThread() const
function LayoutObject:EnclosingRenderFlowThread()
    if (not self:InRenderFlowThread()) then
        return nil;
	end
	-- TODO: in normal conditions, "self.inRenderFlowThread" is false;
end

function LayoutObject:ContainerForRepaint()
    local v = self:View();
    if (not v) then
        return;
	end
    
    local repaintContainer = nil;

--#if USE(ACCELERATED_COMPOSITING)
--    if (v->usesCompositing()) {
--        RenderLayer* compLayer = enclosingLayer()->enclosingCompositingLayer();
--        if (compLayer)
--            repaintContainer = compLayer->renderer();
--    }
--#endif

    -- If we have a flow thread, then we need to do individual repaints within the RenderRegions instead.
    -- Return the flow thread as a repaint container in order to create a chokepoint that allows us to change
    -- repainting to do individual region repaints.
    -- FIXME: Composited layers inside a flow thread will bypass this mechanism and will malfunction. It's not
    -- clear how to address this problem for composited descendants of a RenderFlowThread.
    if (not repaintContainer and self:InRenderFlowThread()) then
        repaintContainer = self:EnclosingRenderFlowThread();
	end
    return repaintContainer;
end

function LayoutObject:ClippedOverflowRectForRepaint(repaintContainer)
    --ASSERT_NOT_REACHED();
    return IntRect:new();
end

function LayoutObject:ContainingBlock()
	local o = self:Parent();
	if (not self:IsText() and self.style:Position() == "FixedPosition") then
        while (o and o:IsLayoutView() and not(o:HasTransform() and o:IsLayoutBlock())) do
            o = o:Parent();
		end
	elseif(not self:IsText() and self.style:Position() == "AbsolutePosition") then
		while (o and (o:Style():Position() == "StaticPosition" or (o:IsInline() and not o:IsReplaced())) and not o:IsLayoutView() and not (o:HasTransform() and o:IsLayoutBlock())) do
			if (o:Style():Position() == "RelativePosition" and o:IsInline() and not o:IsReplaced()) then
                return o:ContainingBlock();
			end
			o = o:Parent();
		end
	else
		while (o and ((o:IsInline() and not o:IsReplaced()) or o:IsTableRow() or o:IsTableSection() or o:IsTableCol() or o:IsFrameSet() or o:IsMedia())) do
			 o = o:Parent();
		end
	end

	if (not o or not o:IsLayoutBlock()) then
        return; -- This can still happen in case of an orphaned tree
	end

	return o;
end

function LayoutObject:WillBeDestroyed()
	--TODO: fixed this function
end

function LayoutObject:Destroy()
    self:WillBeDestroyed();
	--TODO: fixed this function
    --self:ArenaDelete(renderArena(), this);
end

-- virtual function
function LayoutObject:DirtyLinesFromChangedChild(child)
	
end

function LayoutObject:VirtualChildren()
	return;
end

function LayoutObject:AfterPseudoElementRenderer()
	local children = self:VirtualChildren();
	if (children) then
        return children:AfterPseudoElementRenderer(self);
	end
    return nil;
end

function LayoutObject:SetNeedsLayoutAndPrefWidthsRecalc()
	self:SetNeedsLayout(true);
    self:SetPreferredLogicalWidthsDirty(true);
end

function LayoutObject:IsFloatingOrPositioned()
	return self:IsFloating() or self:IsPositioned();
end

function LayoutObject:IsTransparent()
	return self:Style():Opacity() < 1.0;
end

function LayoutObject:Opacity()
	return self:Style():Opacity();
end

function LayoutObject:IsDeprecatedFlexibleBox()
	return false;
end

function LayoutObject:IsFlexingChildren()
	return false;
end

function LayoutObject:IsMarginBeforeQuirk()
	return self.marginBeforeQuirk;
end

function LayoutObject:IsMarginAfterQuirk()
	return self.marginAfterQuirk;
end

function LayoutObject:SetMarginBeforeQuirk(b)
	b = if_else(b == nil, true, b);
	self.marginBeforeQuirk = b;
end

function LayoutObject:SetMarginAfterQuirk(b)
	b = if_else(b == nil, true, b);
	self.marginAfterQuirk = b;
end

function LayoutObject:RenderArena()
	--TODO: fixed this function
	return nil;
end

function LayoutObject:StyleDidChange(diff, oldStyle)
	
end

function LayoutObject:PreservesNewline()
	return self:Style():PreserveNewline();
end

function LayoutObject:IsDescendantOf(obj)
	local r = self;
	while(r) do
		if(r == obj) then
			return true;
		end
		r = r:Parent();
	end
	return false;
end

function LayoutObject:SetHasMarkupTruncation(b)
	b = if_else(b == nil, true, b);
	self.hasMarkupTruncation = b;
end

function LayoutObject:HasMarkupTruncation()
	return self.hasMarkupTruncation;
end

function LayoutObject:SelectionState()
	return self.selectionState;
end

-- Sets the selection state for an object.
function LayoutObject:SetSelectionState(state)
	self.selectionState = state;
end

function LayoutObject:Length()
	return 1;
end

function LayoutObject:CheckForRepaintDuringLayout()
    -- FIXME: <https://bugs.webkit.org/show_bug.cgi?id=20885> It is probably safe to also require
    -- m_everHadLayout. Currently, only RenderBlock::layoutBlock() adds this condition. See also
    -- <https://bugs.webkit.org/show_bug.cgi?id=15129>.
    --return !document()->view()->needsFullRepaint() && !hasLayer();
	return not self:View():FrameView():NeedsFullRepaint();
end

--RenderLayer* RenderObject::findNextLayer(RenderLayer* parentLayer, RenderObject* startPoint, bool checkParent)
function LayoutObject:FindNextLayer(parentLayer, startPoint, checkParent)
    -- Error check the parent layer passed in.  If it's null, we can't find anything.
    if (not parentLayer) then
        return nil;
	end

    -- Step 1: If our layer is a child of the desired parent, then return our layer.
    local ourLayer = if_else(self:HasLayer(), self:Layer(), nil);
    if (ourLayer and ourLayer:Parent() == parentLayer) then
        return ourLayer;
	end

    -- Step 2: If we don't have a layer, or our layer is the desired parent, then descend
    -- into our siblings trying to find the next layer whose parent is the desired parent.
    if (ourLayer == nil or ourLayer == parentLayer) then
		local curr;
		if(startPoint) then
			curr = startPoint:NextSibling();
		else
			curr = self:FirstChild();
		end
		while(curr) do
			local nextLayer = curr:FindNextLayer(parentLayer, nil, false);
            if (nextLayer) then
                return nextLayer;
			end
			curr = curr:NextSibling();
		end
    end

    -- Step 3: If our layer is the desired parent layer, then we're finished.  We didn't
    -- find anything.
    if (parentLayer == ourLayer) then
        return nil;
	end
    -- Step 4: If |checkParent| is set, climb up to our parent and check its siblings that
    -- follow us to see if we can locate a layer.
    if (checkParent and self:Parent() ~= nil) then
        return self:Parent():FindNextLayer(parentLayer, self, true);
	end
    return nil;
end

--RenderLayer* RenderObject::enclosingLayer() const
function LayoutObject:EnclosingLayer()
    local curr = self;
    while (curr) do
        --RenderLayer* layer = curr->hasLayer() ? toRenderBoxModelObject(curr)->layer() : 0;
		local layer = if_else(curr:HasLayer(), curr:Layer(), nil);
        if (layer) then
            return layer;
		end
        curr = curr:Parent();
    end
    return nil;
end

--RenderBox* RenderObject::enclosingBox() const
function LayoutObject:EnclosingBox()
    local curr = self;
    while (curr) do
        if (curr:IsBox()) then
            return curr;
		end
        curr = curr:Parent();
    end
    
    --ASSERT_NOT_REACHED();
    return nil;
end

--RenderBoxModelObject* RenderObject::enclosingBoxModelObject() const
function LayoutObject:EnclosingBoxModelObject()
    local curr = self;
    while (curr) do
        if (curr:IsBoxModelObject()) then
            return curr;
		end
        curr = curr:Parent();
    end

    --ASSERT_NOT_REACHED();
    return nil;
end

--void RenderObject::moveLayers(RenderLayer* oldParent, RenderLayer* newParent)
function LayoutObject:MoveLayers(oldParent, newParent)
    if (not newParent) then
        return;
	end
    if (self:HasLayer()) then
        local layer = self:Layer();
        --ASSERT(oldParent == layer->parent());
        if (oldParent) then
            oldParent:RemoveChild(layer);
		end
        newParent:AddChild(layer);
        return;
    end

	local curr = self:FirstChild()
	while(curr) do
		curr:MoveLayers(oldParent, newParent);
		curr = curr:NextSibling()
	end
end

--static void addLayers(RenderObject* obj, RenderLayer* parentLayer, RenderObject*& newObject, RenderLayer*& beforeChild)
local function addLayers(obj, parentLayer, newObject, beforeChild)
    if (obj:HasLayer()) then
        if (not beforeChild and newObject) then
            -- We need to figure out the layer that follows newObject.  We only do
            -- this the first time we find a child layer, and then we update the
            -- pointer values for newObject and beforeChild used by everyone else.
            beforeChild = newObject:Parent():FindNextLayer(parentLayer, newObject);
            newObject = nil;
        end
        parentLayer:AddChild(obj:Layer(), beforeChild);
        return newObject, beforeChild;
    end

	local curr = obj:FirstChild();
	while(curr) do
		newObject, beforeChild = addLayers(curr, parentLayer, newObject, beforeChild);
		curr = curr:NextSibling();
	end
end

function LayoutObject:AddLayers(parentLayer)
    if (not parentLayer) then
        return;
	end

    local object = self;
    local beforeChild = nil;
    object, beforeChild = addLayers(self, parentLayer, object, beforeChild);
end

function LayoutObject:RemoveLayers(parentLayer)
    if (not parentLayer) then
        return;
	end

    if (self:HasLayer()) then
        parentLayer:RemoveChild(self:Layer());
        return;
    end

	local curr = obj:FirstChild();
	while(curr) do
		curr:RemoveLayers(parentLayer);
		curr = curr:NextSibling();
	end
end

--void RenderObject::computeRectForRepaint(RenderBoxModelObject* repaintContainer, IntRect& rect, bool fixed) const
function LayoutObject:ComputeRectForRepaint(repaintContainer, rect, fixed)
	-- parameter default value;
	fixed = if_else(fixed == nil, false, fixed);

    if (repaintContainer == self) then
        return rect;
	end
	local o = self:Parent();
    if (o) then
        if (o:IsBlockFlow()) then
            --RenderBlock* cb = toRenderBlock(o);
			local cb = o;
            if (cb:HasColumns()) then
                --cb->adjustRectForColumns(rect);
			end
        end

        if (o:HasOverflowClip()) then
            -- o->height() is inaccurate if we're in the middle of a layout of |o|, so use the
            -- layer's size instead.  Even if the layer's size is wrong, the layer itself will repaint
            -- anyway if its size does change.
            local boxParent = o;

            local repaintRect = rect:clone_from_pool();
            repaintRect:Move(-boxParent:Layer():ScrolledContentOffset()); -- For overflow:auto/scroll/hidden.

            local boxRect = IntRect:new_from_pool(IntPoint:new_from_pool(), boxParent:Layer():Size());
            rect = IntRect.Intersection(repaintRect, boxRect);
            if (rect:isEmpty()) then
                return rect;
			end
        end

        rect = o:ComputeRectForRepaint(repaintContainer, rect, fixed);
    end
	return rect;
end

--void RenderObject::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutObject:Paint(paintInfo, paintOffset)
	
end

function LayoutObject:Repaint(immediate)
	
	immediate = if_else(immediate == nil, false, immediate);
    -- Don't repaint if we're unrooted (note that view() still returns the view when unrooted)
    local isRooted, view = self:isRooted();
    if (not isRooted) then
        return;
	end

--    if (view->printing())
--        return; // Don't repaint if we're printing.

    local repaintContainer = self:ContainerForRepaint();
	repaintContainer = repaintContainer or view;
	local rect = self:ClippedOverflowRectForRepaint(repaintContainer);
    self:RepaintUsingContainer(repaintContainer, rect, immediate);
end

--void RenderObject::repaintUsingContainer(RenderBoxModelObject* repaintContainer, const LayoutRect& r, bool immediate)
function LayoutObject:RepaintUsingContainer(repaintContainer, rect, immediate)
    if (not repaintContainer) then
        self:View():RepaintViewRectangle(rect, immediate);
        return;
    end

    if (repaintContainer:IsRenderFlowThread()) then
        --return toRenderFlowThread(repaintContainer)->repaintRectangleInRegions(rect, immediate);
	end

--#if USE(ACCELERATED_COMPOSITING)
--    RenderView* v = view();
--    if (repaintContainer->isRenderView()) {
--        ASSERT(repaintContainer == v);
--        bool viewHasCompositedLayer = v->hasLayer() && v->layer()->isComposited();
--        if (!viewHasCompositedLayer || v->layer()->backing()->paintingGoesToWindow()) {
--            LayoutRect repaintRectangle = r;
--            if (viewHasCompositedLayer &&  v->layer()->transform())
--                repaintRectangle = v->layer()->transform()->mapRect(r);
--            v->repaintViewRectangle(repaintRectangle, immediate);
--            return;
--        }
--    }
--    
--    if (v->usesCompositing()) {
--        ASSERT(repaintContainer->hasLayer() && repaintContainer->layer()->isComposited());
--        repaintContainer->layer()->setBackingNeedsRepaintInRect(r);
--    }
--#else
--    if (repaintContainer->isRenderView())
--        toRenderView(repaintContainer)->repaintViewRectangle(r, immediate);
--#endif

	if (repaintContainer:IsLayoutView()) then
		repaintContainer:RepaintViewRectangle(rect, immediate);
	end
end

--virtual IntRect outlineBoundsForRepaint(RenderBoxModelObject* /*repaintContainer*/, IntPoint* /*cachedOffsetToRepaintContainer*/ = 0) const { return IntRect(); }
function LayoutObject:OutlineBoundsForRepaint(repaintContainer, cachedOffsetToRepaintContainer)
	return IntRect:new();
end

--static bool mustRepaintFillLayers(const RenderObject* renderer, const FillLayer* layer)
local function mustRepaintFillLayers(renderer, layer)
	-- TODO: fixed latter;
	return false;
end

--void RenderObject::repaintRectangle(const LayoutRect& r, bool immediate)
function LayoutObject:RepaintRectangle(rect, immediate)
	
	immediate = if_else(immediate == nil, false, immediate);
    -- Don't repaint if we're unrooted (note that view() still returns the view when unrooted)
	local isRoot, view = self:isRooted();
    if (not isRoot) then
        return;
	end

--    if (view->printing())
--        return; // Don't repaint if we're printing.

	local dirtyRect = rect:clone()
    --LayoutRect dirtyRect(r);

    -- FIXME: layoutDelta needs to be applied in parts before/after transforms and
    -- repaint containers. https://bugs.webkit.org/show_bug.cgi?id=23308
    dirtyRect:Move(view:LayoutDelta());

    local repaintContainer = self:ContainerForRepaint();
    self:ComputeRectForRepaint(repaintContainer, dirtyRect);
	repaintContainer = if_else(repaintContainer, repaintContainer, view)
    self:RepaintUsingContainer(repaintContainer, dirtyRect, immediate);
end

--int RenderObject::maximalOutlineSize(PaintPhase p) const
function LayoutObject:MaximalOutlineSize(p)
--    if (p != PaintPhaseOutline && p != PaintPhaseSelfOutline && p != PaintPhaseChildOutlines)
--        return 0;
    --return toRenderView(document()->renderer())->maximalOutlineSize();
	return self:View():MaximalOutlineSize();
end

function LayoutObject:NeedsPositionedMovementLayoutOnly()
	return self.needsPositionedMovementLayout and not self.needsLayout and not self.normalChildNeedsLayout and not self.posChildNeedsLayout and not self.needsSimplifiedNormalFlowLayout;
end

--function LayoutObject:MustRepaintBackgroundOrBorder()
----    if (self:HasMask() and mustRepaintFillLayers(this, style()->maskLayers()))
----        return true;
--
--    -- If we don't have a background/border/mask, then nothing to do.
--    if (!hasBoxDecorations())
--        return false;
--
--    if (mustRepaintFillLayers(this, style()->backgroundLayers()))
--        return true;
--     
--    // Our fill layers are ok.  Let's check border.
--    if (style()->hasBorder() && borderImageIsLoadedAndCanBeRendered())
--        return true;
--
--    return false;
--}

----bool RenderObject::repaintAfterLayoutIfNeeded(RenderBoxModelObject* repaintContainer, const LayoutRect& oldBounds, const LayoutRect& oldOutlineBox, const LayoutRect* newBoundsPtr, const LayoutRect* newOutlineBoxRectPtr)
--function LayoutObject:RepaintAfterLayoutIfNeeded(repaintContainer, oldBounds, oldOutlineBox, newBoundsPtr, newOutlineBoxRectPtr)
--    local view = self:View();
----    if (v->printing())
----        return false; // Don't repaint if we're printing.
--
--    -- This ASSERT fails due to animations.  See https://bugs.webkit.org/show_bug.cgi?id=37048
--    -- ASSERT(!newBoundsPtr || *newBoundsPtr == clippedOverflowRectForRepaint(repaintContainer));
--    local newBounds = if_else(newBoundsPtr, newBoundsPtr, self:ClippedOverflowRectForRepaint(repaintContainer));
--    local newOutlineBox = LayoutRect:new();
--
--    local fullRepaint = self:SelfNeedsLayout();
--    -- Presumably a background or a border exists if border-fit:lines was specified.
--    if (not fullRepaint and self:Style():BorderFit() == "BorderFitLines") then
--        fullRepaint = true;
--	end
--
--    if (not fullRepaint) then
--        -- This ASSERT fails due to animations.  See https://bugs.webkit.org/show_bug.cgi?id=37048
--        -- ASSERT(!newOutlineBoxRectPtr || *newOutlineBoxRectPtr == outlineBoundsForRepaint(repaintContainer));
--        newOutlineBox = if_else(newOutlineBoxRectPtr, newOutlineBoxRectPtr, self:OutlineBoundsForRepaint(repaintContainer));
--        if (newOutlineBox.location() != oldOutlineBox.location() || (mustRepaintBackgroundOrBorder() && (newBounds != oldBounds || newOutlineBox != oldOutlineBox)))
--            fullRepaint = true;
--    end
--
--    if (!repaintContainer)
--        repaintContainer = v;
--
--    if (fullRepaint) {
--        repaintUsingContainer(repaintContainer, oldBounds);
--        if (newBounds != oldBounds)
--            repaintUsingContainer(repaintContainer, newBounds);
--        return true;
--    }
--
--    if (newBounds == oldBounds && newOutlineBox == oldOutlineBox)
--        return false;
--
--    LayoutUnit deltaLeft = newBounds.x() - oldBounds.x();
--    if (deltaLeft > 0)
--        repaintUsingContainer(repaintContainer, LayoutRect(oldBounds.x(), oldBounds.y(), deltaLeft, oldBounds.height()));
--    else if (deltaLeft < 0)
--        repaintUsingContainer(repaintContainer, LayoutRect(newBounds.x(), newBounds.y(), -deltaLeft, newBounds.height()));
--
--    LayoutUnit deltaRight = newBounds.maxX() - oldBounds.maxX();
--    if (deltaRight > 0)
--        repaintUsingContainer(repaintContainer, LayoutRect(oldBounds.maxX(), newBounds.y(), deltaRight, newBounds.height()));
--    else if (deltaRight < 0)
--        repaintUsingContainer(repaintContainer, LayoutRect(newBounds.maxX(), oldBounds.y(), -deltaRight, oldBounds.height()));
--
--    LayoutUnit deltaTop = newBounds.y() - oldBounds.y();
--    if (deltaTop > 0)
--        repaintUsingContainer(repaintContainer, LayoutRect(oldBounds.x(), oldBounds.y(), oldBounds.width(), deltaTop));
--    else if (deltaTop < 0)
--        repaintUsingContainer(repaintContainer, LayoutRect(newBounds.x(), newBounds.y(), newBounds.width(), -deltaTop));
--
--    LayoutUnit deltaBottom = newBounds.maxY() - oldBounds.maxY();
--    if (deltaBottom > 0)
--        repaintUsingContainer(repaintContainer, LayoutRect(newBounds.x(), oldBounds.maxY(), newBounds.width(), deltaBottom));
--    else if (deltaBottom < 0)
--        repaintUsingContainer(repaintContainer, LayoutRect(oldBounds.x(), newBounds.maxY(), oldBounds.width(), -deltaBottom));
--
--    if (newOutlineBox == oldOutlineBox)
--        return false;
--
--    // We didn't move, but we did change size.  Invalidate the delta, which will consist of possibly
--    // two rectangles (but typically only one).
--    RenderStyle* outlineStyle = outlineStyleForRepaint();
--    LayoutUnit ow = outlineStyle->outlineSize();
--    LayoutUnit width = abs(newOutlineBox.width() - oldOutlineBox.width());
--    if (width) {
--        LayoutUnit shadowLeft;
--        LayoutUnit shadowRight;
--        style()->getBoxShadowHorizontalExtent(shadowLeft, shadowRight);
--
--        LayoutUnit borderRight = isBox() ? toRenderBox(this)->borderRight() : 0;
--        LayoutUnit boxWidth = isBox() ? toRenderBox(this)->width() : 0;
--        LayoutUnit borderWidth = max(-outlineStyle->outlineOffset(), max(borderRight, max(style()->borderTopRightRadius().width().calcValue(boxWidth), style()->borderBottomRightRadius().width().calcValue(boxWidth)))) + max(ow, shadowRight);
--        LayoutRect rightRect(newOutlineBox.x() + min(newOutlineBox.width(), oldOutlineBox.width()) - borderWidth,
--            newOutlineBox.y(),
--            width + borderWidth,
--            max(newOutlineBox.height(), oldOutlineBox.height()));
--        LayoutUnit right = min(newBounds.maxX(), oldBounds.maxX());
--        if (rightRect.x() < right) {
--            rightRect.setWidth(min(rightRect.width(), right - rightRect.x()));
--            repaintUsingContainer(repaintContainer, rightRect);
--        }
--    }
--    LayoutUnit height = abs(newOutlineBox.height() - oldOutlineBox.height());
--    if (height) {
--        LayoutUnit shadowTop;
--        LayoutUnit shadowBottom;
--        style()->getBoxShadowVerticalExtent(shadowTop, shadowBottom);
--
--        LayoutUnit borderBottom = isBox() ? toRenderBox(this)->borderBottom() : 0;
--        LayoutUnit boxHeight = isBox() ? toRenderBox(this)->height() : 0;
--        LayoutUnit borderHeight = max(-outlineStyle->outlineOffset(), max(borderBottom, max(style()->borderBottomLeftRadius().height().calcValue(boxHeight), style()->borderBottomRightRadius().height().calcValue(boxHeight)))) + max(ow, shadowBottom);
--        LayoutRect bottomRect(newOutlineBox.x(),
--            min(newOutlineBox.maxY(), oldOutlineBox.maxY()) - borderHeight,
--            max(newOutlineBox.width(), oldOutlineBox.width()),
--            height + borderHeight);
--        LayoutUnit bottom = min(newBounds.maxY(), oldBounds.maxY());
--        if (bottomRect.y() < bottom) {
--            bottomRect.setHeight(min(bottomRect.height(), bottom - bottomRect.y()));
--            repaintUsingContainer(repaintContainer, bottomRect);
--        }
--    }
--    return false;
--}